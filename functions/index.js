/**
 * Firebase Cloud Function – Territory Run API
 * Region: southamerica-west1
 * Database: Firestore (territory-run-db)
 */

const functions = require("firebase-functions");
const { setGlobalOptions } = functions;
const { onRequest } = functions.https;
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const { MongoClient, ObjectId } = require("mongodb");
const { OAuth2Client } = require("google-auth-library");

admin.initializeApp({
  // Puedes incluir projectId si es necesario
  // projectId: "your-firebase-project-id",
});
const oauthClient = new OAuth2Client();
const GOOGLE_ALLOWED_AUDIENCES = [
  "running-app-uni",
  "https://api-64fkq3y6sq-tl.a.run.app",
  "https://api-28475506464.southamerica-west1.run.app",
  "618104708054-9r9s1c4alg36erliucho9t52n32n6dgq.apps.googleusercontent.com",
];

setGlobalOptions({
  maxInstances: 10,
  region: "southamerica-west1",
});

const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: "2mb" }));

let mongoClientPromise = null;
let mongoDb = null;

const getDb = async () => {
  if (mongoDb) return mongoDb;

  if (!mongoClientPromise) {
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) throw new Error("MONGODB_URI environment variable is not set");
    const client = new MongoClient(mongoUri, {
      serverSelectionTimeoutMS: 5000,
      maxPoolSize: 10,
    });
    mongoClientPromise = client
      .connect()
      .then(() => {
        mongoDb = client.db();
        return mongoDb;
      })
      .catch((error) => {
        mongoClientPromise = null;
        throw error;
      });
  }

  return mongoClientPromise;
};

const getCollection = async (name) => (await getDb()).collection(name);

const toPlainObject = (doc) => {
  if (!doc) return null;
  const { _id, ...rest } = doc;
  return rest;
};

const mapRunDocument = (doc) => {
  const { _id, ...rest } = doc;
  return { id: _id.toString(), ...rest };
};

const parseObjectId = (value) => {
  if (typeof value !== "string") return null;
  if (!ObjectId.isValid(value)) return null;
  return new ObjectId(value);
};

app.get("/test-mongo", async (_req, res) => {
  try {
    const database = await getDb();
    await database.command({ ping: 1 });
    res.json({ success: true, message: "MongoDB connection successful" });
  } catch (error) {
    logger.error("MongoDB connection failed", error);
    res.status(500).json({ success: false, message: "MongoDB connection failed" });
  }
});

// Helpers
const isPlainObject = (value) => Object.prototype.toString.call(value) === "[object Object]";
const ensureBodyObject = (body) => (isPlainObject(body) ? null : "Body must be a JSON object");

const allowedRunFields = [
  "startedAt",
  "endedAt",
  "distanceM",
  "durationS",
  "avgPaceSecPerKm",
  "isClosedCircuit",
  "startLat",
  "startLon",
  "endLat",
  "endLon",
  "routeGeoJson",
  "polygonGeoJson",
  "areaGainedM2",
  "summaryPolyline",
  "simplification",
  "metrics",
  "conditions",
  "storage",
  "synced",
];

const allowedProfileFields = [
  "email",
  "displayName",
  "photoUrl",
  "preferredUnits",
  "level",
  "experience",
  "experienceLevel",
  "totalRuns",
  "totalDistance",
  "totalTime",
  "achievements",
  "lastActivityAt",
  "birthDate",
  "gender",
  "heightCm",
  "weightKg",
  "goalDescription",
  "synced",
  "createdAt",
  "updatedAt",
];

const isFiniteNumber = (value) => typeof value === "number" && Number.isFinite(value);
const isBoolean = (value) => typeof value === "boolean";
const isIsoString = (value) => typeof value === "string" && !Number.isNaN(Date.parse(value));

const validateLineString = (value) => {
  if (!isPlainObject(value)) return "routeGeoJson must be an object";
  if (value.type !== "LineString") return 'routeGeoJson.type must be "LineString"';
  if (!Array.isArray(value.coordinates) || value.coordinates.length === 0)
    return "routeGeoJson.coordinates must be a non-empty array";
  const validCoords = value.coordinates.every(
    (coord) =>
      Array.isArray(coord) &&
      coord.length === 2 &&
      coord.every((num) => typeof num === "number")
  );
  if (!validCoords)
    return "routeGeoJson.coordinates must be an array of [lon, lat] numbers";
  return null;
};

const validatePolygon = (value) => {
  if (!isPlainObject(value)) return "polygonGeoJson must be an object";
  if (value.type !== "Polygon") return 'polygonGeoJson.type must be "Polygon"';
  if (!Array.isArray(value.coordinates) || value.coordinates.length === 0)
    return "polygonGeoJson.coordinates must be a non-empty array";
  const ringsValid = value.coordinates.every(
    (ring) =>
      Array.isArray(ring) &&
      ring.length >= 4 &&
      ring.every(
        (coord) =>
          Array.isArray(coord) &&
          coord.length === 2 &&
          coord.every((num) => typeof num === "number")
      )
  );
  if (!ringsValid) return "polygonGeoJson.coordinates must be an array of linear rings";
  return null;
};

const validateRunPayload = (payload, { partial = false } = {}) => {
  const errors = [];
  if (!partial) {
    ["startedAt", "endedAt", "distanceM", "durationS", "routeGeoJson"].forEach((field) => {
      if (payload[field] === undefined) errors.push(`${field} is required`);
    });
  }
  if (payload.startedAt !== undefined && !isIsoString(payload.startedAt))
    errors.push("startedAt must be an ISO date string");
  if (payload.endedAt !== undefined && !isIsoString(payload.endedAt))
    errors.push("endedAt must be an ISO date string");
  if (payload.distanceM !== undefined && !isFiniteNumber(payload.distanceM))
    errors.push("distanceM must be a number");
  if (payload.durationS !== undefined && (!Number.isInteger(payload.durationS) || payload.durationS < 0))
    errors.push("durationS must be a non-negative integer");
  if (payload.avgPaceSecPerKm !== undefined && !isFiniteNumber(payload.avgPaceSecPerKm))
    errors.push("avgPaceSecPerKm must be a number");
  ["startLat", "startLon", "endLat", "endLon", "areaGainedM2"].forEach((field) => {
    if (payload[field] !== undefined && !isFiniteNumber(payload[field])) {
      errors.push(`${field} must be a number`);
    }
  });
  ["isClosedCircuit", "synced"].forEach((field) => {
    if (payload[field] !== undefined && !isBoolean(payload[field])) {
      errors.push(`${field} must be a boolean`);
    }
  });
  if (payload.routeGeoJson !== undefined) {
    const error = validateLineString(payload.routeGeoJson);
    if (error) errors.push(error);
  }
  if (payload.polygonGeoJson !== undefined) {
    const error = validatePolygon(payload.polygonGeoJson);
    if (error) errors.push(error);
  }
  if (payload.summaryPolyline !== undefined && payload.summaryPolyline !== null && typeof payload.summaryPolyline !== "string") {
    errors.push("summaryPolyline must be a string");
  }
  if (payload.simplification !== undefined) {
    if (!isPlainObject(payload.simplification)) {
      errors.push("simplification must be an object");
    }
  }
  if (payload.metrics !== undefined) {
    if (!isPlainObject(payload.metrics)) {
      errors.push("metrics must be an object");
    } else {
      const { distanceKm, movingTimeS, avgSpeedKmh, paceSecPerKm } = payload.metrics;
      const ensureNumberOrNull = (value, field) => {
        if (value !== undefined && value !== null && !isFiniteNumber(value)) {
          errors.push(`${field} must be a number`);
        }
      };
      ensureNumberOrNull(distanceKm, "metrics.distanceKm");
      ensureNumberOrNull(movingTimeS, "metrics.movingTimeS");
      ensureNumberOrNull(avgSpeedKmh, "metrics.avgSpeedKmh");
      ensureNumberOrNull(paceSecPerKm, "metrics.paceSecPerKm");
    }
  }
  if (payload.conditions !== undefined) {
    if (!isPlainObject(payload.conditions)) {
      errors.push("conditions must be an object");
    } else {
      const { terrain, mood, weather } = payload.conditions;
      if (terrain !== undefined && terrain !== null && typeof terrain !== "string") {
        errors.push("conditions.terrain must be a string");
      }
      if (mood !== undefined && mood !== null && typeof mood !== "string") {
        errors.push("conditions.mood must be a string");
      }
      if (weather !== undefined && weather !== null) {
        if (!isPlainObject(weather)) {
          errors.push("conditions.weather must be an object");
        } else {
          const { condition, temperatureC } = weather;
          if (condition !== undefined && condition !== null && typeof condition !== "string") {
            errors.push("conditions.weather.condition must be a string");
          }
          if (temperatureC !== undefined && temperatureC !== null && !isFiniteNumber(temperatureC)) {
            errors.push("conditions.weather.temperatureC must be a number");
          }
        }
      }
    }
  }
  if (payload.storage !== undefined) {
    if (!isPlainObject(payload.storage)) {
      errors.push("storage must be an object");
    } else {
      const { rawTrackPath, rawTrackUrl, detailedTrackPath, detailedTrackUrl, samples } = payload.storage;
      const ensureStringOrNull = (value, field) => {
        if (value !== undefined && value !== null && typeof value !== "string") {
          errors.push(`${field} must be a string`);
        }
      };
      ensureStringOrNull(rawTrackPath, "storage.rawTrackPath");
      ensureStringOrNull(rawTrackUrl, "storage.rawTrackUrl");
      ensureStringOrNull(detailedTrackPath, "storage.detailedTrackPath");
      ensureStringOrNull(detailedTrackUrl, "storage.detailedTrackUrl");
      if (samples !== undefined && samples !== null) {
        if (!isPlainObject(samples)) {
          errors.push("storage.samples must be an object");
        } else {
          const { raw, smoothed, resampled, simplified } = samples;
          const ensureIntegerOrNull = (value, field) => {
            if (value !== undefined && value !== null && (!Number.isInteger(value) || value < 0)) {
              errors.push(`${field} must be a non-negative integer`);
            }
          };
          ensureIntegerOrNull(raw, "storage.samples.raw");
          ensureIntegerOrNull(smoothed, "storage.samples.smoothed");
          ensureIntegerOrNull(resampled, "storage.samples.resampled");
          ensureIntegerOrNull(simplified, "storage.samples.simplified");
        }
      }
    }
  }
  return errors;
};

const sanitizeRunPayload = (payload) => {
  const result = {};
  allowedRunFields.forEach((field) => {
    if (payload[field] !== undefined) result[field] = payload[field];
  });
  return result;
};

const sanitizeProfilePayload = (payload) => {
  const result = {};
  allowedProfileFields.forEach((field) => {
    if (payload[field] !== undefined) result[field] = payload[field];
  });
  return result;
};

const validateProfilePayload = (payload) => {
  const errors = [];
  const ensureString = (value, field) => {
    if (value !== undefined && typeof value !== "string") errors.push(`${field} must be a string`);
  };
  const ensureNumber = (value, field) => {
    if (value !== undefined && !isFiniteNumber(value)) errors.push(`${field} must be a number`);
  };
  const ensureInteger = (value, field) => {
    if (value !== undefined && (!Number.isInteger(value) || value < 0)) errors.push(`${field} must be a non-negative integer`);
  };

  ensureString(payload.displayName, "displayName");
  ensureString(payload.email, "email");
  ensureString(payload.photoUrl, "photoUrl");
  ensureString(payload.preferredUnits, "preferredUnits");
  ensureString(payload.goalDescription, "goalDescription");
  ensureString(payload.gender, "gender");
  ensureString(payload.experienceLevel, "experienceLevel");

  ensureInteger(payload.level, "level");
  ensureInteger(payload.experience, "experience");
  ensureInteger(payload.totalRuns, "totalRuns");
  ensureNumber(payload.totalDistance, "totalDistance");
  ensureInteger(payload.totalTime, "totalTime");
  ensureNumber(payload.weightKg, "weightKg");
  ensureInteger(payload.heightCm, "heightCm");

  if (payload.achievements !== undefined) {
    if (!Array.isArray(payload.achievements) || !payload.achievements.every((item) => typeof item === "string")) {
      errors.push("achievements must be an array of strings");
    }
  }

  if (payload.birthDate !== undefined && !isIsoString(payload.birthDate)) {
    errors.push("birthDate must be an ISO date string");
  }
  if (payload.lastActivityAt !== undefined && !isIsoString(payload.lastActivityAt)) {
    errors.push("lastActivityAt must be an ISO date string");
  }

  return errors;
};

const getAuthContext = (req) => {
  const uid = req.user?.uid ?? req.user?.sub ?? null;
  const email = req.user?.email ?? "";
  const isServiceAccount = typeof email === "string" && email.endsWith("gserviceaccount.com");
  return { uid, isServiceAccount };
};

// 🔐 Middleware de autenticación con Firebase Auth + Google ID tokens
app.use(async (req, res, next) => {
  if (req.path === "/health") return next();
  if (req.method === "OPTIONS") return res.sendStatus(204);

  try {
    const authHeader = req.headers.authorization || "";
    if (!authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Missing bearer token" });
    }

    const idToken = authHeader.split("Bearer ")[1];
    if (!idToken) {
      return res.status(401).json({ error: "Invalid bearer token" });
    }
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (firebaseError) {
      const message = firebaseError?.message?.toLowerCase?.() ?? "";
      const shouldFallback =
        firebaseError?.errorInfo?.code === "auth/argument-error" ||
        message.includes("audience");
      if (!shouldFallback) {
        logger.error("Firebase token verification failed", firebaseError);
        return res.status(401).json({ error: "Unauthorized", details: firebaseError.message });
      }

      try {
        const ticket = await oauthClient.verifyIdToken({
          idToken,
          audience: GOOGLE_ALLOWED_AUDIENCES,
        });
        decoded = ticket.getPayload();
      } catch (googleError) {
        logger.error("Google token verification failed", googleError);
        return res.status(401).json({ error: "Unauthorized", details: googleError.message });
      }
    }

    const uid = decoded?.uid || decoded?.sub;
    if (!uid) {
      return res.status(401).json({ error: "Invalid decoded token" });
    }

    req.user = { ...decoded, uid };
    next();
  } catch (error) {
    logger.error("Token verification failed", error);
    res.status(401).json({ error: "Unauthorized", details: error.message });
  }
});

// Colecciones
const collectionUsers = "users";
const collectionRuns = "runs";
const collectionTerritory = "territory";

// Rutas
app.get("/health", async (_req, res) => {
  try {
    const database = await getDb();
    await database.command({ ping: 1 });
    res.json({ ok: true, timestamp: new Date().toISOString() });
  } catch (err) {
    logger.error("Healthcheck DB failed", err);
    res.status(500).json({ ok: false, error: "DB check failed" });
  }
});

app.get("/profile/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  const usersCollection = await getCollection(collectionUsers);
  const doc = await usersCollection.findOne({ _id: targetUid });
  if (!doc) return res.status(404).json({ error: "Profile not found" });

  res.json(toPlainObject(doc));
});

app.put("/profile/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitizedInput = sanitizeProfilePayload(req.body);
  const errors = validateProfilePayload(sanitizedInput);
  if (errors.length > 0) return res.status(400).json({ error: "Invalid profile payload", details: errors });

  const now = new Date().toISOString();
  const usersCollection = await getCollection(collectionUsers);
  const existing = await usersCollection.findOne({ _id: targetUid });
  const payload = {
    ...(existing ? toPlainObject(existing) : {}),
    ...sanitizedInput,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  };

  await usersCollection.updateOne({ _id: targetUid }, { $set: payload }, { upsert: true });
  res.json({ success: true });
});

app.patch("/profile/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitizedInput = sanitizeProfilePayload(req.body);
  if (Object.keys(sanitizedInput).length === 0) {
    return res.status(400).json({ error: "No valid profile fields provided" });
  }

  const errors = validateProfilePayload(sanitizedInput);
  if (errors.length > 0) return res.status(400).json({ error: "Invalid profile payload", details: errors });

  const usersCollection = await getCollection(collectionUsers);
  const existing = await usersCollection.findOne({ _id: targetUid });
  if (!existing) return res.status(404).json({ error: "Profile not found" });

  const update = {
    ...sanitizedInput,
    updatedAt: new Date().toISOString(),
  };

  await usersCollection.updateOne({ _id: targetUid }, { $set: update });
  res.json({ success: true });
});

app.get("/territory/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  const territoryCollection = await getCollection(collectionTerritory);
  const doc = await territoryCollection.findOne({ _id: targetUid });
  res.json(doc ? toPlainObject(doc) : {});
});

app.put("/territory/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const now = new Date().toISOString();
  const territoryCollection = await getCollection(collectionTerritory);
  const existing = await territoryCollection.findOne({ _id: targetUid });
  const payload = {
    ...(existing ? toPlainObject(existing) : {}),
    ...req.body,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  };

  await territoryCollection.updateOne({ _id: targetUid }, { $set: payload }, { upsert: true });
  res.json({ success: true });
});

app.get("/runs", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUidParam = typeof req.query.uid === "string" && req.query.uid.trim().length > 0 ? req.query.uid.trim() : null;
  const targetUid = isServiceAccount ? targetUidParam ?? uid : uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  const limit = Math.min(Number(req.query.limit) || 20, 100);
  const runsCollection = await getCollection(collectionRuns);
  const cursor = runsCollection.find({ userId: targetUid }).sort({ startedAt: -1 }).limit(limit);
  const runs = await cursor.toArray();
  res.json(runs.map(mapRunDocument));
});

app.get("/runs/:id", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const objectId = parseObjectId(req.params.id);
  if (!objectId) return res.status(404).json({ error: "Run not found" });

  const runsCollection = await getCollection(collectionRuns);
  const doc = await runsCollection.findOne({ _id: objectId });
  if (!doc) {
    return res.status(404).json({ error: "Run not found" });
  }
  const ownerUid = doc.userId;
  if (!isServiceAccount && ownerUid !== uid) {
    return res.status(404).json({ error: "Run not found" });
  }
  res.json(mapRunDocument(doc));
});

app.post("/runs", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });
  const errors = validateRunPayload(req.body);
  if (errors.length > 0) return res.status(400).json({ error: "Invalid run payload", details: errors });

  const sanitized = sanitizeRunPayload(req.body);
  const now = new Date().toISOString();
  const targetUid = isServiceAccount && typeof req.body.userId === "string" && req.body.userId.trim().length > 0 ? req.body.userId.trim() : uid;
  if (!targetUid) return res.status(400).json({ error: "Missing userId" });

  const runsCollection = await getCollection(collectionRuns);
  const result = await runsCollection.insertOne({
    ...sanitized,
    userId: targetUid,
    createdAt: now,
    updatedAt: now,
  });

  res.status(201).json({ id: result.insertedId.toString(), success: true });
});

app.patch("/runs/:id", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });
  const errors = validateRunPayload(req.body, { partial: true });
  if (errors.length > 0) return res.status(400).json({ error: "Invalid run payload", details: errors });

  const objectId = parseObjectId(req.params.id);
  if (!objectId) {
    return res.status(404).json({ error: "Run not found" });
  }

  const runsCollection = await getCollection(collectionRuns);
  const existing = await runsCollection.findOne({ _id: objectId });
  if (!existing) {
    return res.status(404).json({ error: "Run not found" });
  }
  if (!isServiceAccount && existing.userId !== uid) {
    return res.status(404).json({ error: "Run not found" });
  }

  const updates = { ...sanitizeRunPayload(req.body), updatedAt: new Date().toISOString() };
  await runsCollection.updateOne({ _id: objectId }, { $set: updates });
  res.json({ success: true });
});

app.delete("/runs/:id", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const objectId = parseObjectId(req.params.id);
  if (!objectId) {
    return res.status(404).json({ error: "Run not found" });
  }

  const runsCollection = await getCollection(collectionRuns);
  const existing = await runsCollection.findOne({ _id: objectId });
  if (!existing) {
    return res.status(404).json({ error: "Run not found" });
  }
  if (!isServiceAccount && existing.userId !== uid) {
    return res.status(404).json({ error: "Run not found" });
  }

  await runsCollection.deleteOne({ _id: objectId });
  res.json({ success: true });
});

// Error handler
app.use((err, _req, res, _next) => {
  logger.error("Unhandled error", err);
  res.status(500).json({ error: "Server error", details: err.message });
});

exports.api = onRequest(app);
