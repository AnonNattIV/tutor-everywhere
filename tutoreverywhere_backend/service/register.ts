import express from "express"
import bodyParser from "body-parser";
import bcrypt from "bcrypt";
import { registerStudent, registerTutor } from "../controllers/users.ts";

const registerService = express.Router();

registerService.use(bodyParser.json());
registerService.post("/student", async (req, res) => {
  try {
    const { username, password, firstname, lastname, dateofbirth, gender } = req.body;
    const hashedPassword = await bcrypt.hash(password, 11);
    const register = await registerStudent(username, hashedPassword, firstname, lastname, dateofbirth, gender);
    res.status(200).json({ "message": "Successfully registered account" });
  } catch {
    res.status(500).json({ error: "RegisterService Error" });
  }
});

registerService.post("/tutor", async (req, res) => {
  try {
    const { username, password, firstname, lastname, dateofbirth, gender } = req.body;
    const hashedPassword = await bcrypt.hash(password, 11);
    const register = await registerTutor(username, hashedPassword, firstname, lastname, dateofbirth, gender);
    res.status(200).json({ "message": "Successfully registered account" });
  } catch {
    res.status(500).json({ error: "RegisterService Error" });
  }
});

export default registerService