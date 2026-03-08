import sql from "../db/db.ts";

async function getAppointmentByUserId(userId: string, date: string) {
  try {
    const startDate = new Date(date);
    startDate.setHours(0, 0, 0, 0);
    
    const endDate = new Date(date);
    endDate.setHours(23, 59, 59, 999);

    console.log(date);
    const appointments = await sql`
      select
      a.appointment_id,
      a.tutor_id,
      t.firstname as tutor_firstname,
      t.lastname as tutor_lastname,
      t.verified as tutor_verified,
      a.student_id,
      s.firstname as student_firstname,
      s.lastname as student_lastname,
      s.verified as student_verified,
      a.start_date,
      a.end_date,
      a.place_name,
      a.description,
      a.subject
      from appointments as a
      join tutors as t on t.user_uuid = a.tutor_id
      join students as s on s.user_uuid = a.student_id
      where start_date >= ${startDate}
      and start_date < ${endDate}
      and tutor_id = ${userId}
      order by start_date asc
    `
    return appointments
  } catch (err) {
    console.error("Get Appointments by Tutor Id Error")
    throw err;
  }
}

export { getAppointmentByUserId }