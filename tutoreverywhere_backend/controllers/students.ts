import sql from "../db/db.ts";

async function viewStudentData(userId: string) {
  try {
    const student = await sql`
      select user_uuid, firstname, lastname, dateofbirth, gender, profile_picture, bio, verified
      from students
      where user_uuid = ${userId}
    `;

    return student;
  } catch (err) {
    console.error("View Student Data Error");
    throw err;
  }
}

export { viewStudentData }