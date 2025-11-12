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

const mapDocumentWithId = (doc) => {
  if (!doc) return null;
  const { _id, ...rest } = doc;
  return {
    id: typeof _id === "object" && _id !== null && typeof _id.toString === "function" ? _id.toString() : _id,
    ...rest,
  };
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

app.delete("/runs", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const queryUid = typeof req.query.uid === "string" && req.query.uid.trim().length > 0 ? req.query.uid.trim() : null;
  const targetUid = queryUid ?? uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  try {
    const runsCollection = await getCollection(collectionRuns);
    const result = await runsCollection.deleteMany({ userId: targetUid });
    res.json({ success: true, deletedCount: result.deletedCount ?? 0 });
  } catch (error) {
    logger.error("Failed to delete runs", error);
    res.status(500).json({ error: "Failed to delete runs" });
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
  "polyline",
  "simplification",
  "metrics",
  "conditions",
  "storage",
  "synced",
  "processingStats",
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
  "goalType",
  "weeklyDistanceGoal",
  "synced",
  "createdAt",
  "updatedAt",
];

const allowedConsentFields = [
  "termsVersion",
  "privacyVersion",
  "locationConsent",
  "analyticsConsent",
  "marketingConsent",
  "ageConfirmed",
  "acceptedAt",
  "source",
];

const VALID_ARCO_TYPES = ["access", "rectify", "delete", "revoke"];
const VALID_ARCO_STATUSES = ["open", "in_progress", "closed"];
const VALID_REWARD_TYPES = ["milestone", "legendary"];

const ADMIN_UIDS = new Set(
  (process.env.ADMIN_UIDS || "")
    .split(",")
    .map((uid) => uid.trim())
    .filter((uid) => uid.length > 0),
);

const PUBLIC_GET_PATHS = new Set(["/legal/documents"]);

const isFiniteNumber = (value) => typeof value === "number" && Number.isFinite(value);
const isBoolean = (value) => typeof value === "boolean";
const isIsoString = (value) => typeof value === "string" && !Number.isNaN(Date.parse(value));

// Level system helpers (must match client-side LevelSystem constants)
const LEVEL_SYSTEM = {
  MAX_LEVEL: 50,
  BASE_XP: 100,
  EXPONENT: 1.5,
};

const xpForLevel = (level) => {
  if (level <= 1) return 0;
  return Math.round(LEVEL_SYSTEM.BASE_XP * Math.pow(level - 1, LEVEL_SYSTEM.EXPONENT));
};

const totalXpForLevel = (level) => {
  if (level <= 1) return 0;
  let total = 0;
  for (let i = 2; i <= level; i += 1) {
    total += xpForLevel(i);
  }
  return total;
};

const levelFromXp = (totalXp) => {
  if (!Number.isFinite(totalXp) || totalXp <= 0) return 1;
  for (let level = 1; level <= LEVEL_SYSTEM.MAX_LEVEL; level += 1) {
    if (totalXp < totalXpForLevel(level + 1)) {
      return level;
    }
  }
  return LEVEL_SYSTEM.MAX_LEVEL;
};

const sanitizeAchievementsPayload = (payload) => {
  if (!isPlainObject(payload)) return null;
  const { achievements, totalXp, unlockedCount } = payload;
  if (!isPlainObject(achievements)) return null;
  const sanitizedAchievements = {};
  Object.entries(achievements).forEach(([key, value]) => {
    if (!isPlainObject(value)) return;
    const currentValue = Number.isFinite(value.currentValue) ? Number(value.currentValue) : 0;
    const isUnlocked = Boolean(value.isUnlocked);
    const unlockedAt = value.unlockedAt && isIsoString(value.unlockedAt) ? new Date(value.unlockedAt).toISOString() : null;
    sanitizedAchievements[key] = {
      currentValue,
      isUnlocked,
      unlockedAt,
    };
  });

  return {
    achievements: sanitizedAchievements,
    totalXp: Number.isFinite(totalXp) ? Number(totalXp) : 0,
    unlockedCount: Number.isFinite(unlockedCount) ? Number(unlockedCount) : 0,
  };
};

const validateAchievementsPayload = (payload) => {
  const errors = [];
  if (!payload) {
    errors.push("Payload must be an object");
    return errors;
  }
  if (!isPlainObject(payload.achievements)) {
    errors.push("achievements must be an object");
  }
  if (!Number.isFinite(payload.totalXp)) {
    errors.push("totalXp must be a number");
  }
  if (!Number.isFinite(payload.unlockedCount)) {
    errors.push("unlockedCount must be a number");
  }
  return errors;
};

const sanitizeLevelProgressPayload = (payload) => {
  if (!isPlainObject(payload)) return null;
  const totalXp = Number.isFinite(payload.totalXp) ? Number(payload.totalXp) : 0;
  const level = Number.isFinite(payload.level) ? Number(payload.level) : levelFromXp(totalXp);
  const updatedAt = payload.updatedAt && isIsoString(payload.updatedAt)
    ? new Date(payload.updatedAt).toISOString()
    : new Date().toISOString();
  return {
    totalXp,
    level,
    updatedAt,
  };
};

const validateLevelProgressPayload = (payload) => {
  const errors = [];
  if (!payload) {
    errors.push("Payload must be an object");
    return errors;
  }
  if (!Number.isFinite(payload.totalXp)) {
    errors.push("totalXp must be a number");
  }
  if (!Number.isFinite(payload.level)) {
    errors.push("level must be a number");
  }
  return errors;
};

const sanitizeMilestonePayload = (payload) => {
  if (!isPlainObject(payload)) return null;
  const base = {
    oldLevel: Number.isFinite(payload.oldLevel) ? Number(payload.oldLevel) : 0,
    newLevel: Number.isFinite(payload.newLevel) ? Number(payload.newLevel) : 0,
    xpGained: Number.isFinite(payload.xpGained) ? Number(payload.xpGained) : 0,
    totalXp: Number.isFinite(payload.totalXp) ? Number(payload.totalXp) : 0,
    rewardType:
      typeof payload.rewardType === "string" && VALID_REWARD_TYPES.includes(payload.rewardType)
        ? payload.rewardType
        : null,
    achievedAt: payload.achievedAt && isIsoString(payload.achievedAt)
      ? new Date(payload.achievedAt).toISOString()
      : new Date().toISOString(),
  };
  return base;
};

const validateMilestonePayload = (payload) => {
  const errors = [];
  if (!payload) {
    errors.push("Payload must be an object");
    return errors;
  }
  ["oldLevel", "newLevel", "xpGained", "totalXp"].forEach((field) => {
    if (!Number.isFinite(payload[field])) {
      errors.push(`${field} must be a number`);
    }
  });
  if (payload.rewardType !== null && payload.rewardType !== undefined && !VALID_REWARD_TYPES.includes(payload.rewardType)) {
    errors.push(`rewardType must be one of ${VALID_REWARD_TYPES.join(", ")}`);
  }
  if (payload.achievedAt !== undefined && !isIsoString(payload.achievedAt)) {
    errors.push("achievedAt must be an ISO string");
  }
  return errors;
};

const isAdminUid = (uid) => uid && ADMIN_UIDS.has(uid);

const sanitizeConsentPayload = (payload) => {
  const sanitized = {};
  allowedConsentFields.forEach((field) => {
    if (payload[field] !== undefined) sanitized[field] = payload[field];
  });
  return sanitized;
};

const validateConsentPayload = (payload) => {
  const errors = [];
  if (!payload.termsVersion || typeof payload.termsVersion !== "string") {
    errors.push("termsVersion is required");
  }
  if (!payload.privacyVersion || typeof payload.privacyVersion !== "string") {
    errors.push("privacyVersion is required");
  }
  if (!isBoolean(payload.locationConsent) || !payload.locationConsent) {
    errors.push("locationConsent must be true");
  }
  if (!isBoolean(payload.ageConfirmed) || !payload.ageConfirmed) {
    errors.push("ageConfirmed must be true");
  }
  ["analyticsConsent", "marketingConsent"].forEach((field) => {
    if (payload[field] !== undefined && !isBoolean(payload[field])) {
      errors.push(`${field} must be a boolean`);
    }
  });
  if (payload.acceptedAt !== undefined && !isIsoString(payload.acceptedAt)) {
    errors.push("acceptedAt must be an ISO string");
  }
  if (payload.source !== undefined && typeof payload.source !== "string") {
    errors.push("source must be a string");
  }
  return errors;
};

const validateArcoPayload = (payload) => {
  const errors = [];
  if (!payload.type || typeof payload.type !== "string" || !VALID_ARCO_TYPES.includes(payload.type)) {
    errors.push(`type must be one of ${VALID_ARCO_TYPES.join(", ")}`);
  }
  if (payload.message === undefined || typeof payload.message !== "string" || payload.message.trim().length === 0) {
    errors.push("message is required");
  }
  if (payload.contactEmail !== undefined && typeof payload.contactEmail !== "string") {
    errors.push("contactEmail must be a string");
  }
  return errors;
};

const validateArcoUpdatePayload = (payload) => {
  const errors = [];
  if (payload.status !== undefined && !VALID_ARCO_STATUSES.includes(payload.status)) {
    errors.push(`status must be one of ${VALID_ARCO_STATUSES.join(", ")}`);
  }
  if (payload.notes !== undefined && typeof payload.notes !== "string") {
    errors.push("notes must be a string");
  }
  if (payload.handlerUserId !== undefined && typeof payload.handlerUserId !== "string") {
    errors.push("handlerUserId must be a string");
  }
  return errors;
};

const getClientInfo = (req) => {
  const forwardedFor = req.headers["x-forwarded-for"];
  const ip = typeof forwardedFor === "string" && forwardedFor.length > 0
    ? forwardedFor.split(",")[0].trim()
    : req.ip;
  const userAgent = typeof req.headers["user-agent"] === "string" ? req.headers["user-agent"] : null;
  return { ipAddress: ip, userAgent };
};

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
  if (payload.polyline !== undefined && payload.polyline !== null && typeof payload.polyline !== "string") {
    errors.push("polyline must be a string");
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
  if (payload.processingStats !== undefined) {
    if (!isPlainObject(payload.processingStats)) {
      errors.push("processingStats must be an object");
    } else {
      const { originalPoints, processedPoints, reductionRate } = payload.processingStats;
      const ensureNumberOrNull = (value, field) => {
        if (value !== undefined && value !== null && !isFiniteNumber(value)) {
          errors.push(`${field} must be a number`);
        }
      };
      ensureNumberOrNull(originalPoints, "processingStats.originalPoints");
      ensureNumberOrNull(processedPoints, "processingStats.processedPoints");
      ensureNumberOrNull(reductionRate, "processingStats.reductionRate");
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
  ensureString(payload.goalType, "goalType");
  ensureString(payload.gender, "gender");
  ensureString(payload.experienceLevel, "experienceLevel");

  ensureInteger(payload.level, "level");
  ensureInteger(payload.experience, "experience");
  ensureInteger(payload.totalRuns, "totalRuns");
  ensureNumber(payload.totalDistance, "totalDistance");
  ensureInteger(payload.totalTime, "totalTime");
  ensureNumber(payload.weightKg, "weightKg");
  ensureInteger(payload.heightCm, "heightCm");
  ensureNumber(payload.weeklyDistanceGoal, "weeklyDistanceGoal");

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
  if (req.method === "GET" && PUBLIC_GET_PATHS.has(req.path)) return next();
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
const collectionLegalDocuments = "legal_documents";
const collectionLegalConsents = "legal_consents";
const collectionLegalConsentHistory = "legal_consent_history";
const collectionArcoRequests = "arco_requests";
const collectionAchievements = "achievements";
const collectionLevelProgress = "level_progress";
const collectionLevelMilestones = "level_milestones";

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

app.delete("/profile/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  try {
    const usersCollection = await getCollection(collectionUsers);
    const achievementsCollection = await getCollection(collectionAchievements);
    const levelCollection = await getCollection(collectionLevelProgress);
    const milestonesCollection = await getCollection(collectionLevelMilestones);
    const territoryCollection = await getCollection(collectionTerritory);
    const runsCollection = await getCollection(collectionRuns);

    await Promise.all([
      achievementsCollection.deleteOne({ userId: targetUid }),
      levelCollection.deleteOne({ userId: targetUid }),
      milestonesCollection.deleteMany({ userId: targetUid }),
      territoryCollection.deleteOne({ _id: targetUid }),
      runsCollection.deleteMany({ userId: targetUid }),
    ]);

    const result = await usersCollection.deleteOne({ _id: targetUid });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Profile not found" });
    }

    res.json({ success: true });
  } catch (error) {
    logger.error("Failed to delete profile", error);
    res.status(500).json({ error: "Failed to delete profile" });
  }
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

// ========= ACHIEVEMENTS =========

const mapAchievementDocument = (doc) => {
  if (!doc) {
    return null;
  }
  const mapped = mapDocumentWithId(doc);
  return {
    id: mapped.id,
    userId: mapped.userId,
    achievements: mapped.achievements ?? {},
    totalXp: mapped.totalXp ?? 0,
    unlockedCount: mapped.unlockedCount ?? 0,
    updatedAt: mapped.updatedAt ?? null,
    createdAt: mapped.createdAt ?? null,
  };
};

app.get("/achievements/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  try {
    const achievementsCollection = await getCollection(collectionAchievements);
    const doc = await achievementsCollection.findOne({ userId: targetUid });
    if (!doc) {
      return res.json({
        userId: targetUid,
        achievements: {},
        totalXp: 0,
        unlockedCount: 0,
        createdAt: null,
        updatedAt: null,
      });
    }
    res.json(mapAchievementDocument(doc));
  } catch (error) {
    logger.error("Failed to fetch achievements", error);
    res.status(500).json({ error: "Failed to fetch achievements" });
  }
});

app.put("/achievements/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitized = sanitizeAchievementsPayload(req.body);
  const errors = validateAchievementsPayload(sanitized);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid achievements payload", details: errors });
  }

  try {
    const achievementsCollection = await getCollection(collectionAchievements);
    const now = new Date().toISOString();
    const payload = {
      userId: targetUid,
      achievements: sanitized.achievements,
      totalXp: sanitized.totalXp,
      unlockedCount: sanitized.unlockedCount,
      updatedAt: now,
    };

    const result = await achievementsCollection.findOneAndUpdate(
      { userId: targetUid },
      {
        $set: payload,
        $setOnInsert: {
          createdAt: now,
        },
      },
      {
        upsert: true,
        returnDocument: "after",
      },
    );

    const updatedDoc = result.value ?? payload;
    res.json(mapAchievementDocument(updatedDoc));
  } catch (error) {
    logger.error("Failed to save achievements", error);
    res.status(500).json({ error: "Failed to save achievements" });
  }
});

app.post("/achievements/:uid/unlock", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const { achievementId, currentValue, unlockedAt } = req.body;
  if (typeof achievementId !== "string" || achievementId.trim().length === 0) {
    return res.status(400).json({ error: "achievementId is required" });
  }

  const normalizedId = achievementId.trim();
  const normalizedUnlockedAt = unlockedAt && isIsoString(unlockedAt)
    ? new Date(unlockedAt).toISOString()
    : new Date().toISOString();
  const normalizedCurrentValue = Number.isFinite(currentValue) ? Number(currentValue) : null;

  try {
    const achievementsCollection = await getCollection(collectionAchievements);
    const now = new Date().toISOString();
    const doc = await achievementsCollection.findOne({ userId: targetUid });
    const achievements = (doc && isPlainObject(doc.achievements)) ? { ...doc.achievements } : {};
    const existingEntry = achievements[normalizedId] ?? {};
    const existingCurrentValue = Number.isFinite(existingEntry.currentValue)
      ? Number(existingEntry.currentValue)
      : 0;

    achievements[normalizedId] = {
      currentValue: normalizedCurrentValue ?? Math.max(existingCurrentValue, 1),
      isUnlocked: true,
      unlockedAt: normalizedUnlockedAt,
    };

    const unlockedCount = Object.values(achievements).filter((entry) => entry && entry.isUnlocked).length;

    const payload = {
      userId: targetUid,
      achievements,
      totalXp: doc?.totalXp ?? 0,
      unlockedCount,
      updatedAt: now,
    };

    const result = await achievementsCollection.findOneAndUpdate(
      { userId: targetUid },
      {
        $set: payload,
        $setOnInsert: {
          createdAt: now,
        },
      },
      {
        upsert: true,
        returnDocument: "after",
      },
    );

    const updatedDoc = result.value ?? payload;
    res.json(mapAchievementDocument(updatedDoc));
  } catch (error) {
    logger.error("Failed to unlock achievement", error);
    res.status(500).json({ error: "Failed to unlock achievement" });
  }
});

// ========= LEVEL PROGRESSION =========

const mapLevelProgressDocument = (doc) => {
  if (!doc) return null;
  return {
    userId: doc.userId,
    totalXp: doc.totalXp ?? 0,
    level: doc.level ?? levelFromXp(doc.totalXp ?? 0),
    updatedAt: doc.updatedAt ?? null,
    createdAt: doc.createdAt ?? null,
  };
};

const mapMilestoneDocument = (doc) => {
  if (!doc) return null;
  const mapped = mapDocumentWithId(doc);
  return {
    id: mapped.id,
    userId: mapped.userId,
    oldLevel: mapped.oldLevel ?? 0,
    newLevel: mapped.newLevel ?? 0,
    xpGained: mapped.xpGained ?? 0,
    totalXp: mapped.totalXp ?? 0,
    rewardType: mapped.rewardType ?? null,
    achievedAt: mapped.achievedAt ?? null,
    createdAt: mapped.createdAt ?? null,
  };
};

app.get("/level/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  try {
    const levelCollection = await getCollection(collectionLevelProgress);
    const doc = await levelCollection.findOne({ userId: targetUid });
    if (!doc) {
      return res.json({
        userId: targetUid,
        totalXp: 0,
        level: 1,
        createdAt: null,
        updatedAt: null,
      });
    }
    res.json(mapLevelProgressDocument(doc));
  } catch (error) {
    logger.error("Failed to fetch level progress", error);
    res.status(500).json({ error: "Failed to fetch level progress" });
  }
});

app.put("/level/:uid", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitized = sanitizeLevelProgressPayload(req.body);
  const errors = validateLevelProgressPayload(sanitized);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid level progress payload", details: errors });
  }

  try {
    const levelCollection = await getCollection(collectionLevelProgress);
    const now = new Date().toISOString();
    const totalXp = Math.max(0, Math.trunc(sanitized.totalXp));
    const level = Math.min(LEVEL_SYSTEM.MAX_LEVEL, Math.max(1, Math.trunc(levelFromXp(totalXp))));

    const payload = {
      userId: targetUid,
      totalXp,
      level,
      updatedAt: sanitized.updatedAt ?? now,
    };

    const result = await levelCollection.findOneAndUpdate(
      { userId: targetUid },
      {
        $set: payload,
        $setOnInsert: {
          createdAt: now,
        },
      },
      { upsert: true, returnDocument: "after" },
    );

    const updatedDoc = result.value ?? payload;
    res.json(mapLevelProgressDocument(updatedDoc));
  } catch (error) {
    logger.error("Failed to save level progress", error);
    res.status(500).json({ error: "Failed to save level progress" });
  }
});

app.post("/level/:uid/increment", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const xpDeltaRaw = req.body?.xpDelta;
  if (!Number.isFinite(xpDeltaRaw)) {
    return res.status(400).json({ error: "xpDelta must be a number" });
  }

  const xpDelta = Math.trunc(xpDeltaRaw);

  try {
    const levelCollection = await getCollection(collectionLevelProgress);
    const now = new Date().toISOString();
    const existing = await levelCollection.findOne({ userId: targetUid });
    const currentXp = Number.isFinite(existing?.totalXp) ? Number(existing.totalXp) : 0;
    const newXp = Math.max(0, currentXp + xpDelta);
    const newLevel = Math.min(LEVEL_SYSTEM.MAX_LEVEL, Math.max(1, Math.trunc(levelFromXp(newXp))));

    const result = await levelCollection.findOneAndUpdate(
      { userId: targetUid },
      {
        $set: {
          userId: targetUid,
          totalXp: newXp,
          level: newLevel,
          updatedAt: now,
        },
        $setOnInsert: {
          createdAt: now,
        },
      },
      { upsert: true, returnDocument: "after" },
    );

    const updatedDoc = result.value ?? {
      userId: targetUid,
      totalXp: newXp,
      level: newLevel,
      updatedAt: now,
      createdAt: now,
    };

    res.json(mapLevelProgressDocument(updatedDoc));
  } catch (error) {
    logger.error("Failed to increment level progress", error);
    res.status(500).json({ error: "Failed to increment level progress" });
  }
});

app.get("/level/:uid/milestones", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });

  const limitParam = Number(req.query.limit);
  const limit = Number.isFinite(limitParam) ? Math.min(Math.max(Math.trunc(limitParam), 1), 50) : 20;

  try {
    const milestonesCollection = await getCollection(collectionLevelMilestones);
    const cursor = milestonesCollection
      .find({ userId: targetUid })
      .sort({ achievedAt: -1, createdAt: -1 })
      .limit(limit);
    const results = await cursor.toArray();
    res.json(results.map(mapMilestoneDocument));
  } catch (error) {
    logger.error("Failed to fetch level milestones", error);
    res.status(500).json({ error: "Failed to fetch level milestones" });
  }
});

app.post("/level/:uid/milestones", async (req, res) => {
  const { uid, isServiceAccount } = getAuthContext(req);
  const targetUid = req.params.uid;
  if (!targetUid) return res.status(400).json({ error: "Missing uid" });
  if (!isServiceAccount && targetUid !== uid) return res.status(403).json({ error: "Forbidden" });
  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitized = sanitizeMilestonePayload(req.body);
  const errors = validateMilestonePayload(sanitized);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid milestone payload", details: errors });
  }

  try {
    const milestonesCollection = await getCollection(collectionLevelMilestones);
    const now = new Date().toISOString();
    const payload = {
      userId: targetUid,
      oldLevel: sanitized.oldLevel,
      newLevel: sanitized.newLevel,
      xpGained: sanitized.xpGained,
      totalXp: sanitized.totalXp,
      rewardType: sanitized.rewardType,
      achievedAt: sanitized.achievedAt ?? now,
      createdAt: now,
    };

    const result = await milestonesCollection.insertOne(payload);
    const inserted = {
      _id: result.insertedId,
      ...payload,
    };
    res.status(201).json(mapMilestoneDocument(inserted));
  } catch (error) {
    logger.error("Failed to save level milestone", error);
    res.status(500).json({ error: "Failed to save level milestone" });
  }
});

// ========= LEGAL & COMPLIANCE =========

app.get("/legal/documents", async (_req, res) => {
  try {
    const documentsCollection = await getCollection(collectionLegalDocuments);
    const documents = await documentsCollection.find({}).sort({ publishedAt: -1 }).toArray();
    res.json(documents.map(mapDocumentWithId));
  } catch (error) {
    logger.error("Failed to list legal documents", error);
    res.status(500).json({ error: "Failed to fetch legal documents" });
  }
});

app.get("/legal/consent/me", async (req, res) => {
  const { uid } = getAuthContext(req);
  if (!uid) return res.status(401).json({ error: "Unauthorized" });
  try {
    const legalConsents = await getCollection(collectionLegalConsents);
    const doc = await legalConsents.findOne({ userId: uid });
    if (!doc) return res.status(404).json({ error: "Consent not found" });
    res.json(toPlainObject(doc));
  } catch (error) {
    logger.error("Failed to fetch consent", error);
    res.status(500).json({ error: "Failed to fetch consent" });
  }
});

app.put("/legal/consent", async (req, res) => {
  const { uid } = getAuthContext(req);
  if (!uid) return res.status(401).json({ error: "Unauthorized" });

  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const sanitized = sanitizeConsentPayload(req.body);
  const errors = validateConsentPayload(sanitized);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid consent payload", details: errors });
  }

  const { ipAddress, userAgent } = getClientInfo(req);
  const now = new Date();
  const acceptedAtIso = sanitized.acceptedAt ? new Date(sanitized.acceptedAt).toISOString() : now.toISOString();

  const consentDocument = {
    userId: uid,
    termsVersion: sanitized.termsVersion,
    privacyVersion: sanitized.privacyVersion,
    locationConsent: sanitized.locationConsent,
    analyticsConsent: sanitized.analyticsConsent ?? false,
    marketingConsent: sanitized.marketingConsent ?? false,
    ageConfirmed: sanitized.ageConfirmed,
    acceptedAt: acceptedAtIso,
    source: sanitized.source ?? "mobile_app",
    ipAddress,
    userAgent,
    updatedAt: now.toISOString(),
  };

  try {
    const legalConsents = await getCollection(collectionLegalConsents);
    const legalConsentHistory = await getCollection(collectionLegalConsentHistory);

    const existing = await legalConsents.findOne({ userId: uid });
    const createdAt = existing?.createdAt ?? now.toISOString();

    await legalConsents.updateOne(
      { userId: uid },
      {
        $set: {
          ...consentDocument,
          createdAt,
        },
      },
      { upsert: true },
    );

    await legalConsentHistory.insertOne({
      ...consentDocument,
      createdAt,
      recordedAt: now.toISOString(),
    });

    res.json({
      success: true,
      consent: {
        ...consentDocument,
        createdAt,
      },
    });
  } catch (error) {
    logger.error("Failed to persist consent", error);
    res.status(500).json({ error: "Failed to save consent" });
  }
});

app.post("/arco-requests", async (req, res) => {
  const { uid } = getAuthContext(req);
  if (!uid) return res.status(401).json({ error: "Unauthorized" });

  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const errors = validateArcoPayload(req.body);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid ARCO payload", details: errors });
  }

  const { ipAddress, userAgent } = getClientInfo(req);
  const nowIso = new Date().toISOString();

  const arcoDoc = {
    userId: uid,
    type: req.body.type,
    message: req.body.message.trim(),
    contactEmail: req.body.contactEmail ?? null,
    status: "open",
    createdAt: nowIso,
    updatedAt: nowIso,
    ipAddress,
    userAgent,
  };

  try {
    const arcoCollection = await getCollection(collectionArcoRequests);
    const result = await arcoCollection.insertOne(arcoDoc);
    const insertedId = result.insertedId?.toString?.() ?? result.insertedId;
    logger.info("ARCO request created", { userId: uid, id: insertedId, type: arcoDoc.type });
    res.status(201).json({ success: true, id: insertedId });
  } catch (error) {
    logger.error("Failed to create ARCO request", error);
    res.status(500).json({ error: "Failed to create ARCO request" });
  }
});

app.get("/arco-requests", async (req, res) => {
  const { uid } = getAuthContext(req);
  if (!uid || !isAdminUid(uid)) return res.status(403).json({ error: "Forbidden" });

  try {
    const filter = {};
    if (typeof req.query.type === "string" && VALID_ARCO_TYPES.includes(req.query.type)) {
      filter.type = req.query.type;
    }
    if (typeof req.query.status === "string" && VALID_ARCO_STATUSES.includes(req.query.status)) {
      filter.status = req.query.status;
    }

    const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 200);
    const arcoCollection = await getCollection(collectionArcoRequests);
    const cursor = arcoCollection.find(filter).sort({ createdAt: -1 }).limit(limit);
    const results = await cursor.toArray();
    res.json(results.map(mapDocumentWithId));
  } catch (error) {
    logger.error("Failed to list ARCO requests", error);
    res.status(500).json({ error: "Failed to list ARCO requests" });
  }
});

app.patch("/arco-requests/:id", async (req, res) => {
  const { uid } = getAuthContext(req);
  if (!uid || !isAdminUid(uid)) return res.status(403).json({ error: "Forbidden" });

  const invalid = ensureBodyObject(req.body);
  if (invalid) return res.status(400).json({ error: invalid });

  const errors = validateArcoUpdatePayload(req.body);
  if (errors.length > 0) {
    return res.status(400).json({ error: "Invalid ARCO update payload", details: errors });
  }

  const objectId = parseObjectId(req.params.id);
  if (!objectId) return res.status(404).json({ error: "ARCO request not found" });

  const updates = {};
  if (req.body.status) {
    updates.status = req.body.status;
  }
  if (req.body.notes !== undefined) {
    updates.notes = req.body.notes;
  }
  if (req.body.handlerUserId !== undefined) {
    updates.handlerUserId = req.body.handlerUserId;
  } else if (req.body.status) {
    updates.handlerUserId = uid;
  }

  const nowIso = new Date().toISOString();
  updates.updatedAt = nowIso;
  if (updates.status === "closed") {
    updates.closedAt = nowIso;
  }

  try {
    const arcoCollection = await getCollection(collectionArcoRequests);
    const result = await arcoCollection.findOneAndUpdate(
      { _id: objectId },
      { $set: updates },
      { returnDocument: "after" },
    );
    if (!result.value) return res.status(404).json({ error: "ARCO request not found" });
    res.json({ success: true, request: mapDocumentWithId(result.value) });
  } catch (error) {
    logger.error("Failed to update ARCO request", error);
    res.status(500).json({ error: "Failed to update ARCO request" });
  }
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

// 🌤️ Obtener clima automáticamente usando Google Weather API
async function fetchWeatherForLocation(lat, lon) {
  try {
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      logger.warn("GOOGLE_MAPS_API_KEY not configured");
      return null;
    }

    // Google Weather API - Current Conditions
    // Documentación: https://developers.google.com/maps/documentation/weather/overview
    const weatherUrl = `https://weather.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;
    
    const weatherResponse = await fetch(weatherUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        location: {
          latLng: {
            latitude: lat,
            longitude: lon,
          },
        },
        languageCode: "es",
        units: "METRIC",
      }),
    });

    if (!weatherResponse.ok) {
      logger.warn("Weather API failed:", weatherResponse.status, await weatherResponse.text());
      return null;
    }

    const weatherData = await weatherResponse.json();
    
    // Extraer datos relevantes de la respuesta de Google Weather API
    const currentConditions = weatherData.currentConditions;
    if (!currentConditions) {
      logger.warn("No current conditions in weather response");
      return null;
    }

    return {
      condition: currentConditions.weatherDescription || "Desconocido",
      temperatureC: currentConditions.temperature?.value || null,
      humidity: currentConditions.humidity || null,
      windSpeed: currentConditions.windSpeed?.value || null,
      windDirection: currentConditions.windDirection?.degrees || null,
      uvIndex: currentConditions.uvIndex || null,
      cloudCover: currentConditions.cloudCover || null,
      visibility: currentConditions.visibility?.value || null,
      source: "google-weather-api",
      fetchedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("Error fetching weather:", error);
    return null;
  }
}

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

  // 🌤️ NUEVO: Obtener clima automáticamente en background
  const runId = result.insertedId;
  const startLat = sanitized.startLat;
  const startLon = sanitized.startLon;
  
  if (startLat && startLon) {
    // Ejecutar en background (no bloquear respuesta)
    fetchWeatherForLocation(startLat, startLon)
      .then(async (weatherData) => {
        if (weatherData) {
          // Actualizar el documento con los datos del clima
          await runsCollection.updateOne(
            { _id: runId },
            { 
              $set: { 
                "conditions.weather": {
                  condition: weatherData.condition,
                  temperatureC: weatherData.temperatureC,
                  humidity: weatherData.humidity,
                  windSpeed: weatherData.windSpeed,
                  source: weatherData.source,
                  fetchedAt: weatherData.fetchedAt,
                },
              },
            }
          );
          logger.info(`Weather data added to run ${runId}`);
        }
      })
      .catch((error) => {
        logger.error(`Failed to fetch weather for run ${runId}:`, error);
      });
  }

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

// ========== TERRITORY ENDPOINTS ==========

 

// Error handler
app.use((err, _req, res, _next) => {
  logger.error("Unhandled error", err);
  res.status(500).json({ error: "Server error", details: err.message });
});

// 📦 Export user data (callable)
exports.exportUserData = functions.https.onCall(async (request) => {
  try {
    const callerUid = request?.auth?.uid || null;
    if (!callerUid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const reqUserId = request?.data?.userId;
    const targetUid = typeof reqUserId === 'string' && reqUserId.trim().length > 0 ? reqUserId.trim() : callerUid;
    if (targetUid !== callerUid) {
      // Solo permitir exportar tus propios datos
      throw new functions.https.HttpsError('permission-denied', 'Cannot export data for another user');
    }

    const usersCollection = await getCollection(collectionUsers);
    const runsCollection = await getCollection(collectionRuns);
    const territoryCollection = await getCollection(collectionTerritory);

    const [profileDoc, runs, territoryById, territoryByUser] = await Promise.all([
      usersCollection.findOne({ _id: targetUid }),
      runsCollection.find({ userId: targetUid }).sort({ startedAt: -1 }).toArray(),
      territoryCollection.findOne({ _id: targetUid }),
      territoryCollection.findOne({ userId: targetUid }),
    ]);

    const exportPayload = {
      userId: targetUid,
      generatedAt: new Date().toISOString(),
      profile: profileDoc ? toPlainObject(profileDoc) : null,
      runs: Array.isArray(runs) ? runs.map(mapRunDocument) : [],
      territory: territoryByUser || territoryById ? toPlainObject(territoryByUser || territoryById) : null,
      meta: {
        version: 1,
        collections: {
          users: collectionUsers,
          runs: collectionRuns,
          territory: collectionTerritory,
        },
      },
    };

    const bucket = admin.storage().bucket();
    const filePath = `exports/${targetUid}/export-${Date.now()}.json`;
    const file = bucket.file(filePath);
    const jsonBuffer = Buffer.from(JSON.stringify(exportPayload));
    await file.save(jsonBuffer, {
      contentType: 'application/json; charset=utf-8',
      resumable: false,
      metadata: { cacheControl: 'no-cache' },
    });

    const expiresMs = Date.now() + 24 * 60 * 60 * 1000; // 24h
    const [signedUrl] = await file.getSignedUrl({
      action: 'read',
      expires: expiresMs,
    });

    const [metadata] = await file.getMetadata();
    return {
      downloadUrl: signedUrl,
      fileSize: metadata?.size || null,
      expiresAt: new Date(expiresMs).toISOString(),
      path: filePath,
    };
  } catch (error) {
    logger.error('exportUserData failed', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', error?.message || 'Export failed');
  }
});

exports.api = onRequest(app);
