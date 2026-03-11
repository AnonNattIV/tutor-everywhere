import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import fs from "fs/promises";
import path from "path";
import { v7 as uuidv7 } from "uuid";

type ObjectStorageConfig = {
  bucket: string;
  endpoint?: string;
  accessKeyId: string;
  secretAccessKey: string;
  region: string;
  forcePathStyle: boolean;
};

let cachedClient: S3Client | null = null;
let cachedConfig: ObjectStorageConfig | null = null;
let hasLoadedConfig = false;

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

function resolveUploadsDir() {
  return (
    firstEnv("UPLOADS_DIR", "UPLOAD_DIR", "RAILWAY_VOLUME_MOUNT_PATH") ||
    path.join(process.cwd(), "uploads")
  );
}

function resolveUploadsPublicUrl() {
  const configured =
    firstEnv("UPLOADS_PUBLIC_URL", "UPLOAD_PUBLIC_URL", "FILE_PUBLIC_URL") ||
    "/uploads";
  return normalizeUrl(configured);
}

function buildUploadUrl(key: string) {
  const normalizedKey = key.replace(/^\/+/, "");
  return `${resolveUploadsPublicUrl()}/${normalizedKey}`;
}

function shouldForceLocalUpload() {
  const mode = firstEnv(
    "UPLOAD_STORAGE",
    "STORAGE_DRIVER",
    "FILE_STORAGE_DRIVER",
  ).toLowerCase();
  return mode === "local" || mode === "volume" || mode === "filesystem";
}

function sanitizePathSegment(segment: string) {
  const sanitized = segment
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return sanitized || "misc";
}

function loadConfig(): ObjectStorageConfig | null {
  if (hasLoadedConfig) return cachedConfig;

  const bucket = firstEnv(
    "OBJECT_STORAGE_BUCKET",
    "S3_BUCKET",
    "AWS_S3_BUCKET",
    "AWS_S3_BUCKET_NAME",
    "AWS_BUCKET_NAME",
    "BUCKET_NAME",
  );
  const endpoint = firstEnv(
    "OBJECT_STORAGE_ENDPOINT",
    "S3_ENDPOINT",
    "AWS_ENDPOINT_URL_S3",
    "AWS_ENDPOINT_URL",
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
    firstEnv(
      "OBJECT_STORAGE_REGION",
      "S3_REGION",
      "AWS_REGION",
      "AWS_DEFAULT_REGION",
    ) || "auto";
  const forcePathStyleValue = firstEnv(
    "OBJECT_STORAGE_FORCE_PATH_STYLE",
    "S3_FORCE_PATH_STYLE",
    "AWS_S3_FORCE_PATH_STYLE",
  );
  const forcePathStyle = forcePathStyleValue
    ? parseBoolean(forcePathStyleValue, false)
    : false;

  const missing = [];
  if (!bucket) missing.push("OBJECT_STORAGE_BUCKET");
  if (!accessKeyId) missing.push("OBJECT_STORAGE_ACCESS_KEY_ID");
  if (!secretAccessKey) missing.push("OBJECT_STORAGE_SECRET_ACCESS_KEY");

  const hasAnyObjectStorageSetting = !!(
    bucket ||
    endpoint ||
    accessKeyId ||
    secretAccessKey
  );

  if (missing.length > 0) {
    if (hasAnyObjectStorageSetting && !shouldForceLocalUpload()) {
      throw new Error(
        `Object storage is not fully configured. Missing env: ${missing.join(", ")}`,
      );
    }
    cachedConfig = null;
    hasLoadedConfig = true;
    return cachedConfig;
  }

  cachedConfig = {
    bucket,
    endpoint: endpoint || undefined,
    accessKeyId,
    secretAccessKey,
    region,
    forcePathStyle,
  };
  hasLoadedConfig = true;
  return cachedConfig;
}

function getClient() {
  if (cachedClient) return cachedClient;

  const config = loadConfig();
  if (!config) {
    throw new Error("Object storage config is unavailable");
  }

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

async function uploadImageToLocalStorage(
  file: Express.Multer.File,
  folder: string,
) {
  const safeFolder = sanitizePathSegment(folder);
  const extension = resolveImageExtension(file.originalname, file.mimetype);
  const fileName = `${uuidv7()}${extension}`;
  const uploadsDir = resolveUploadsDir();
  const destinationDir = path.join(uploadsDir, safeFolder);
  const destinationPath = path.join(destinationDir, fileName);

  await fs.mkdir(destinationDir, { recursive: true });
  await fs.writeFile(destinationPath, file.buffer);

  return buildUploadUrl(`${safeFolder}/${fileName}`);
}

export async function uploadImageToObjectStorage(
  file: Express.Multer.File,
  folder: string,
) {
  if (!file || !file.buffer) {
    throw new Error("No image file buffer received");
  }

  if (shouldForceLocalUpload()) {
    return uploadImageToLocalStorage(file, folder);
  }

  const config = loadConfig();
  if (!config) {
    return uploadImageToLocalStorage(file, folder);
  }

  const client = getClient();
  const extension = resolveImageExtension(file.originalname, file.mimetype);
  const safeFolder = sanitizePathSegment(folder);
  const key = `${safeFolder}/${uuidv7()}${extension}`;

  await client.send(
    new PutObjectCommand({
      Bucket: config.bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    }),
  );

  return buildUploadUrl(key);
}

export async function getImageFromObjectStorage(key: string) {
  if (shouldForceLocalUpload()) {
    return null;
  }

  const config = loadConfig();
  if (!config) {
    return null;
  }

  try {
    const client = getClient();
    const response = await client.send(
      new GetObjectCommand({
        Bucket: config.bucket,
        Key: key,
      }),
    );

    return {
      body: response.Body,
      contentType: response.ContentType?.toString(),
    };
  } catch (err: any) {
    const status = err?.$metadata?.httpStatusCode;
    const errorName = err?.name || err?.Code;
    if (status === 404 || errorName === "NoSuchKey" || errorName === "NotFound") {
      return null;
    }
    throw err;
  }
}
