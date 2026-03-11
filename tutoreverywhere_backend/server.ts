import dotenv from "dotenv/config";
import express from "express";
import morgan from "morgan";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
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

const app = express();
app.use(morgan("combined"));

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
