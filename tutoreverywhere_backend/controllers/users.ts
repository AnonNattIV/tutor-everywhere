import sql from "../db/db.ts";
import { v7 as uuidv7 } from "uuid";

async function isUsernameExist(username: string) {
  try {
    const user = await sql`
      select username from users where username = ${username}
    `;

    return user.length;
  } catch (err) {
    console.error("isUsernameExist error");
  }
}

async function findUserByUserId(userId: string) {
  try {
    const user = await sql`
      select user_uuid, username, password, role from users where user_uuid = ${userId}
    `;

    return user[0];
  } catch (err) {
    console.error("findUserByUserId error");
  }
}

async function findUserByUsername(username: string) {
  try {
    const user = await sql`
      select user_uuid, username, password, role from users where username = ${username}
    `;

    return user[0];
  } catch (err) {
    console.error("findUserByUsername error");
  }
}

async function registerUser(username: string, password: string, role: string) {
  const uuid = uuidv7();
  try {
    const user = await sql`
      insert into users (user_uuid, username, password, role)
      values (${uuid}, ${username}, ${password}, ${role})
    `;

    return user;
  } catch (err) {
    console.error("registerUser Error");
  }
}

async function registerStudent(username: string, password: string, firstname: string, lastname: string, dateofbirth: string, gender: string) {
  const uuid = uuidv7();
  try {
    const [user, student] = await sql.begin(async (tx) => {
      const [user] = await tx`
        insert into users (user_uuid, username, password, role)
        values (${uuid}, ${username}, ${password}, 'student')
        returning *
      `

      const [student] = await tx`
        insert into students (user_uuid, firstname, lastname, dateofbirth, gender)
        values (${uuid}, ${firstname}, ${lastname}, ${dateofbirth}, ${gender})
        returning *
      `

      return [user, student]
    }) 
  } catch (err) {
    console.error("Register Student Error");
    throw err;
  }
}

async function registerTutor(username: string, password: string, firstname: string, lastname: string, dateofbirth: string, gender: string) {
  const uuid = uuidv7();
  try {
    const [user, tutor] = await sql.begin(async (tx) => {
      const [user] = await tx`
        insert into users (user_uuid, username, password, role)
        values (${uuid}, ${username}, ${password}, 'tutor')
        returning *
      `

      const [tutor] = await tx`
        insert into tutors (user_uuid, firstname, lastname, dateofbirth, gender)
        values (${uuid}, ${firstname}, ${lastname}, ${dateofbirth}, ${gender})
        returning *
      `

      return [user, tutor]
    }) 
  } catch (err) {
    console.error("Register Tutor Error");
    throw err;
  }
}

export { isUsernameExist, findUserByUserId, findUserByUsername, registerUser, registerStudent, registerTutor };
