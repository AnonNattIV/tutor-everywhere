import dotenv from "dotenv/config";
import express from "express";
import morgan from "morgan";
import authService from "./service/auth.ts";
import userService from "./service/user.ts";
import registerService from "./service/register.ts";

const app = express();
app.use(morgan("combined"));

app.use("/auth", authService);
app.use("/user", userService);
app.use("/register", registerService);

app.get("/", (req, res) => {
  res.send("Hello World");
});

app.listen(3000, () => {
  console.log("Server is running on http://localhost:3000");
});
