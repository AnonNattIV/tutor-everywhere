import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import path from "path";
import { v7 as uuidv7 } from "uuid";

type ObjectStorageConfig = {
  bucket: string;
  endpoint?: string;
  publicUrl: string;
  accessKeyId: string;
  secretAccessKey: string;
  region: string;
  forcePathStyle: boolean;
};

let cachedClient: S3Client | null = null;
let cachedConfig: ObjectStorageConfig | null = null;

function firstEnv(...keys: string[]) {
  for (const key of keys) {
    const value = process.env[key];
    if (value && value.trim().length > 0) {
      return value.trim();
    }
  }
  return "";
}

function parseBoolean(value: string, fallback: boolean) {
  const normalized = value.trim().toLowerCase();
  if (normalized === "true" || normalized === "1" || normalized === "yes") {
    return true;
  }

  if (normalized === "false" || normalized === "0" || normalized === "no") {
    return false;
  }

  return fallback;
}

function normalizeUrl(url: string) {
  return url.replace(/\/+$/, "");
}

function resolveImageExtension(originalName: string, mimeType: string) {
  const extensionFromName = path.extname(originalName || "").toLowerCase();
  if (extensionFromName) {
    return extensionFromName;
  }

  if (mimeType === "image/jpeg") return ".jpg";
  if (mimeType === "image/png") return ".png";
  if (mimeType === "image/webp") return ".webp";
  if (mimeType === "image/gif") return ".gif";

  return ".bin";
}

function loadConfig(): ObjectStorageConfig {
  if (cachedConfig) return cachedConfig;

  const bucket = firstEnv(
    "OBJECT_STORAGE_BUCKET",
    "S3_BUCKET",
    "AWS_S3_BUCKET",
    "BUCKET_NAME",
  );
  const endpoint = firstEnv(
    "OBJECT_STORAGE_ENDPOINT",
    "S3_ENDPOINT",
    "AWS_ENDPOINT_URL_S3",
    "AWS_ENDPOINT_URL",
  );
  const publicUrl = firstEnv(
    "OBJECT_STORAGE_PUBLIC_URL",
    "S3_PUBLIC_URL",
    "ASSET_BASE_URL",
  );
  const accessKeyId = firstEnv(
    "OBJECT_STORAGE_ACCESS_KEY_ID",
    "S3_ACCESS_KEY_ID",
    "AWS_ACCESS_KEY_ID",
  );
  const secretAccessKey = firstEnv(
    "OBJECT_STORAGE_SECRET_ACCESS_KEY",
    "S3_SECRET_ACCESS_KEY",
    "AWS_SECRET_ACCESS_KEY",
  );
  const region =
    firstEnv("OBJECT_STORAGE_REGION", "S3_REGION", "AWS_REGION") || "auto";
  const forcePathStyleValue = firstEnv(
    "OBJECT_STORAGE_FORCE_PATH_STYLE",
    "S3_FORCE_PATH_STYLE",
  );
  const forcePathStyle = forcePathStyleValue
    ? parseBoolean(forcePathStyleValue, true)
    : true;

  const missing = [];
  if (!bucket) missing.push("OBJECT_STORAGE_BUCKET");
  if (!publicUrl) missing.push("OBJECT_STORAGE_PUBLIC_URL");
  if (!accessKeyId) missing.push("OBJECT_STORAGE_ACCESS_KEY_ID");
  if (!secretAccessKey) missing.push("OBJECT_STORAGE_SECRET_ACCESS_KEY");

  if (missing.length > 0) {
    throw new Error(
      `Object storage is not fully configured. Missing env: ${missing.join(", ")}`,
    );
  }

  cachedConfig = {
    bucket,
    endpoint: endpoint || undefined,
    publicUrl: normalizeUrl(publicUrl),
    accessKeyId,
    secretAccessKey,
    region,
    forcePathStyle,
  };
  return cachedConfig;
}

function getClient() {
  if (cachedClient) return cachedClient;

  const config = loadConfig();
  cachedClient = new S3Client({
    region: config.region,
    endpoint: config.endpoint,
    forcePathStyle: config.forcePathStyle,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
  });

  return cachedClient;
}

export async function uploadImageToObjectStorage(
  file: Express.Multer.File,
  folder: string,
) {
  if (!file || !file.buffer) {
    throw new Error("No image file buffer received");
  }

  const config = loadConfig();
  const client = getClient();
  const extension = resolveImageExtension(file.originalname, file.mimetype);
  const safeFolder = folder.replace(/^\/+|\/+$/g, "");
  const key = `${safeFolder}/${uuidv7()}${extension}`;

  await client.send(
    new PutObjectCommand({
      Bucket: config.bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    }),
  );

  return `${config.publicUrl}/${key}`;
}
