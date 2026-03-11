import sql from "../db/db.ts";

type AppointmentDateQuery = {
  year: number;
  month: number;
  day?: number;
};

function buildDateRange({ year, month, day }: AppointmentDateQuery) {
  const startDate = day == null
    ? new Date(year, month - 1, 1)
    : new Date(year, month - 1, day);
  startDate.setHours(0, 0, 0, 0);

  const endDate = day == null
    ? new Date(year, month, 1)
    : new Date(year, month - 1, day + 1);
  endDate.setHours(0, 0, 0, 0);

  return { startDate, endDate };
}

async function getAppointmentByTutorId(
  userId: string,
  dateQuery: AppointmentDateQuery,
) {
  try {
    const { startDate, endDate } = buildDateRange(dateQuery);

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
      a.subject,
      a.latitude,
      a.longitude
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


async function getAppointmentByStudentId(
  userId: string,
  dateQuery: AppointmentDateQuery,
) {
  try {
    const { startDate, endDate } = buildDateRange(dateQuery);

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
      a.subject,
      a.latitude,
      a.longitude
      from appointments as a
      join tutors as t on t.user_uuid = a.tutor_id
      join students as s on s.user_uuid = a.student_id
      where start_date >= ${startDate}
      and start_date < ${endDate}
      and student_id = ${userId}
      order by start_date asc
    `
    return appointments
  } catch (err) {
    console.error("Get Appointments by Tutor Id Error")
    throw err;
  }
}

export { getAppointmentByTutorId, getAppointmentByStudentId }
