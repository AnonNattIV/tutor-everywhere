import sql from "../db/db.ts";

async function viewTutorData(userId: string) {
  try {
    const tutor = await sql`
      select user_uuid, firstname, lastname, dateofbirth, gender, profile_picture, bio
      from tutors
      where user_uuid = ${userId}
    `;

    return tutor;
  } catch (err) {
    console.error("View Tutor Data Error");
    throw err;
  }
}

export { viewTutorData }