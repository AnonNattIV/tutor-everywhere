import dotenv from "dotenv/config";
import express from "express";
import morgan from "morgan";
import authService from "./service/auth.ts";
import userService from "./service/user.ts";
import registerService from "./service/register.ts";
import tutorService from "./service/tutors.ts";
import studentService from "./service/students.ts";
import reviewService from "./service/reviews.ts";
import chatService from "./service/chat.ts";

const app = express();
app.use(morgan("combined"));

app.use('/assets', express.static('assets'));

app.use("/auth", authService);
app.use("/user", userService);
app.use("/register", registerService);
app.use("/tutors", tutorService); 
app.use("/students", studentService);
app.use("/reviews", reviewService);
app.use("/chat", chatService);

app.get("/", (req, res) => {
  res.send("Hello World");
});

app.listen(3000, () => {
  console.log("Server is running on http://localhost:3000");
});
