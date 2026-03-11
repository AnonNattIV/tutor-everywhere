import dotenv from "dotenv/config";
import express from "express";
import morgan from "morgan";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import sql from "./db/db.ts";
import { getImageFromObjectStorage } from "./helpers/objectStorage.ts";
import authService from "./service/auth.ts";
import userService from "./service/user.ts";
import registerService from "./service/register.ts";
import tutorService from "./service/tutors.ts";
import studentService from "./service/students.ts";
import reviewService from "./service/reviews.ts";
import chatService from "./service/chat.ts";
import adminService from "./service/admin.ts";
import supportService from "./service/support.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const assetsDir = path.join(__dirname, "assets");
const pfpDir = path.join(assetsDir, "pfp");
const defaultPfpPath = path.join(pfpDir, "default_pfp.png");
const uploadsDir =
  process.env.UPLOADS_DIR ||
  process.env.UPLOAD_DIR ||
  process.env.RAILWAY_VOLUME_MOUNT_PATH ||
  path.join(__dirname, "uploads");

const app = express();
app.use(morgan("combined"));
fs.mkdirSync(uploadsDir, { recursive: true });

async function ensureCoreProfileSchema() {
  try {
    await sql.unsafe(`
      do $$
      begin
        if to_regclass('public.tutors') is not null then
          alter table tutors add column if not exists profile_picture text;
          alter table tutors add column if not exists promptpay_picture text;
          alter table tutors add column if not exists verification_picture text;
          alter table tutors add column if not exists bio text;
          alter table tutors add column if not exists verified boolean default false;
          alter table tutors add column if not exists preferred_place text;
          alter table tutors add column if not exists province text;
          alter table tutors add column if not exists location text;

          update tutors
          set profile_picture = 'assets/pfp/default_pfp.png'
          where profile_picture is null or btrim(profile_picture) = '';
        end if;

        if to_regclass('public.students') is not null then
          alter table students add column if not exists profile_picture text;
          alter table students add column if not exists bio text;
          alter table students add column if not exists verified boolean default false;

          update students
          set profile_picture = 'assets/pfp/default_pfp.png'
          where profile_picture is null or btrim(profile_picture) = '';
        end if;
      end $$;
    `);
  } catch (err) {
    console.error("Core profile schema initialization failed", err);
  }
}

ensureCoreProfileSchema();

// Fallback to default profile image when DB points to a missing file.
app.get("/assets/pfp/:filename", (req, res, next) => {
  const rawFilename = req.params.filename ?? "";
  const safeFilename = path.basename(rawFilename);

  if (rawFilename !== safeFilename) {
    return res.status(400).send("Invalid file path");
  }

  const requestedPath = path.join(pfpDir, safeFilename);
  if (fs.existsSync(requestedPath)) {
    return res.sendFile(requestedPath);
  }

  if (fs.existsSync(defaultPfpPath)) {
    return res.sendFile(defaultPfpPath);
  }

  return next();
});

app.use("/assets", express.static(assetsDir));
app.get(/^\/uploads\/(.+)/, async (req, res, next) => {
  const rawKey = req.params[0]?.toString?.() ?? "";
  const objectKey = rawKey.replace(/^\/+/, "");

  if (!objectKey || objectKey.includes("..")) {
    return next();
  }

  const absoluteUploadsDir = path.resolve(uploadsDir);
  const localPath = path.resolve(uploadsDir, objectKey);
  if (!localPath.startsWith(absoluteUploadsDir)) {
    return res.status(400).send("Invalid file path");
  }

  if (fs.existsSync(localPath)) {
    return res.sendFile(localPath);
  }

  try {
    const objectFile = await getImageFromObjectStorage(objectKey);
    if (!objectFile) {
      return next();
    }

    if (objectFile.contentType) {
      res.setHeader("Content-Type", objectFile.contentType);
    }

    const responseBody: any = objectFile.body;
    if (responseBody && typeof responseBody.pipe === "function") {
      responseBody.pipe(res);
      return;
    }

    if (Buffer.isBuffer(responseBody) || responseBody instanceof Uint8Array) {
      return res.send(responseBody);
    }

    if (
      responseBody &&
      typeof responseBody.transformToByteArray === "function"
    ) {
      const bytes = await responseBody.transformToByteArray();
      return res.send(Buffer.from(bytes));
    }

    return res.status(500).json({ message: "Unsupported uploaded file stream" });
  } catch (err) {
    console.error("Error loading uploaded file from object storage", err);
    return res.status(500).json({ message: "Error loading uploaded file" });
  }
});
app.use("/uploads", express.static(uploadsDir));

app.use("/auth", authService);
app.use("/user", userService);
app.use("/register", registerService);
app.use("/tutors", tutorService); 
app.use("/students", studentService);
app.use("/reviews", reviewService);
app.use("/chat", chatService);
app.use('/admin', adminService);
app.use("/support", supportService);

app.get("/", (req, res) => {
  res.send("Hello World");
});

const port = Number(process.env.PORT) || 3000;

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
