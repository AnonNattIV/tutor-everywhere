import sql from "../db/db.ts";
import { v7 as uuidv7 } from "uuid";

type SupportTicketStatus = "open" | "archived";

async function ensureSupportTables() {
  try {
    await sql`
      create table if not exists support_tickets (
        ticket_id uuid primary key,
        user_id uuid not null references users(user_uuid) on delete cascade,
        admin_id uuid references users(user_uuid) on delete set null,
        status text not null default 'open',
        created_at timestamptz not null default now(),
        updated_at timestamptz not null default now(),
        archived_at timestamptz,
        check (status in ('open', 'archived'))
      )
    `;

    await sql`
      create table if not exists support_messages (
        message_id uuid primary key,
        ticket_id uuid not null references support_tickets(ticket_id) on delete cascade,
        sender_id uuid not null references users(user_uuid) on delete cascade,
        message_text text not null,
        created_at timestamptz not null default now(),
        check (length(trim(message_text)) > 0)
      )
    `;

    await sql`
      create index if not exists support_tickets_user_created_idx
      on support_tickets (user_id, created_at desc)
    `;

    await sql`
      create index if not exists support_tickets_status_created_idx
      on support_tickets (status, created_at desc)
    `;

    await sql`
      create index if not exists support_messages_ticket_created_idx
      on support_messages (ticket_id, created_at asc)
    `;
  } catch (err) {
    console.error("Ensure Support Tables Error");
    throw err;
  }
}

async function getDefaultAdminId() {
  try {
    const [row] = await sql`
      select user_uuid
      from users
      where role = 'admin'
      order by user_uuid asc
      limit 1
    `;

    return row?.user_uuid?.toString?.() ?? "";
  } catch (err) {
    console.error("Get Default Admin Error");
    throw err;
  }
}

async function createSupportTicketForUser(userId: string) {
  const adminId = await getDefaultAdminId();
  if (!adminId) {
    throw new Error("No admin account available");
  }

  const ticketId = uuidv7();
  const status: SupportTicketStatus = "open";

  try {
    const [ticket] = await sql`
      insert into support_tickets (
        ticket_id,
        user_id,
        admin_id,
        status
      )
      values (
        ${ticketId},
        ${userId},
        ${adminId},
        ${status}
      )
      returning *
    `;

    return ticket;
  } catch (err) {
    console.error("Create Support Ticket Error");
    throw err;
  }
}

async function getOpenSupportTicketForUser(userId: string) {
  try {
    const [ticket] = await sql`
      select *
      from support_tickets
      where user_id = ${userId} and status = 'open'
      order by created_at desc
      limit 1
    `;

    return ticket;
  } catch (err) {
    console.error("Get Open Support Ticket Error");
    throw err;
  }
}

async function getOrCreateOpenSupportTicketForUser(userId: string) {
  const openTicket = await getOpenSupportTicketForUser(userId);
  if (openTicket) return { ticket: openTicket, created: false as const };

  const createdTicket = await createSupportTicketForUser(userId);
  return { ticket: createdTicket, created: true as const };
}

async function getSupportTicketById(ticketId: string) {
  try {
    const [ticket] = await sql`
      select *
      from support_tickets
      where ticket_id = ${ticketId}
      limit 1
    `;

    return ticket;
  } catch (err) {
    console.error("Get Support Ticket By Id Error");
    throw err;
  }
}

async function getSupportTicketDetails(ticketId: string) {
  try {
    const [ticket] = await sql`
      select
        t.ticket_id,
        t.user_id,
        t.admin_id,
        t.status,
        t.created_at,
        t.updated_at,
        t.archived_at,
        u.username as user_username,
        u.role as user_role,
        coalesce(s.firstname, tu.firstname, u.username) as user_firstname,
        coalesce(s.lastname, tu.lastname, '') as user_lastname
      from support_tickets as t
      join users as u on u.user_uuid = t.user_id
      left join students as s on s.user_uuid = t.user_id
      left join tutors as tu on tu.user_uuid = t.user_id
      where t.ticket_id = ${ticketId}
      limit 1
    `;

    return ticket;
  } catch (err) {
    console.error("Get Support Ticket Details Error");
    throw err;
  }
}

async function listSupportTicketsForUser(userId: string) {
  try {
    const tickets = await sql`
      select
        t.ticket_id,
        t.user_id,
        t.admin_id,
        t.status,
        t.created_at,
        t.updated_at,
        t.archived_at
      from support_tickets as t
      where t.user_id = ${userId}
      order by t.created_at desc
    `;

    return tickets;
  } catch (err) {
    console.error("List Support Tickets For User Error");
    throw err;
  }
}

async function listSupportMessages(ticketId: string, limit: number = 500) {
  try {
    const messages = await sql`
      select
        message_id,
        ticket_id,
        sender_id,
        message_text,
        created_at
      from support_messages
      where ticket_id = ${ticketId}
      order by created_at asc, message_id asc
      limit ${limit}
    `;

    return messages;
  } catch (err) {
    console.error("List Support Messages Error");
    throw err;
  }
}

async function sendSupportMessage(
  ticketId: string,
  senderId: string,
  text: string,
) {
  const messageId = uuidv7();

  try {
    const [message] = await sql`
      insert into support_messages (
        message_id,
        ticket_id,
        sender_id,
        message_text
      )
      values (
        ${messageId},
        ${ticketId},
        ${senderId},
        ${text}
      )
      returning
        message_id,
        ticket_id,
        sender_id,
        message_text,
        created_at
    `;

    await sql`
      update support_tickets
      set updated_at = now()
      where ticket_id = ${ticketId}
    `;

    return message;
  } catch (err) {
    console.error("Send Support Message Error");
    throw err;
  }
}

async function archiveSupportTicket(ticketId: string) {
  const archivedStatus: SupportTicketStatus = "archived";

  try {
    const [ticket] = await sql`
      update support_tickets
      set
        status = ${archivedStatus},
        updated_at = now(),
        archived_at = coalesce(archived_at, now())
      where ticket_id = ${ticketId}
      returning *
    `;

    return ticket;
  } catch (err) {
    console.error("Archive Support Ticket Error");
    throw err;
  }
}

async function listSupportUsersForAdmin() {
  try {
    const rows = await sql`
      with per_user as (
        select
          user_id,
          max(created_at) as latest_created_at,
          count(*) filter (where status = 'open') as open_count
        from support_tickets
        group by user_id
      ),
      latest_ticket as (
        select distinct on (user_id)
          user_id,
          ticket_id as latest_ticket_id,
          status as latest_ticket_status,
          created_at as latest_ticket_created_at
        from support_tickets
        order by user_id, created_at desc, ticket_id desc
      )
      select
        p.user_id,
        u.username,
        u.role,
        coalesce(s.firstname, tu.firstname, u.username) as firstname,
        coalesce(s.lastname, tu.lastname, '') as lastname,
        l.latest_ticket_id,
        l.latest_ticket_status,
        l.latest_ticket_created_at,
        p.open_count
      from per_user as p
      join users as u on u.user_uuid = p.user_id
      left join latest_ticket as l on l.user_id = p.user_id
      left join students as s on s.user_uuid = p.user_id
      left join tutors as tu on tu.user_uuid = p.user_id
      order by p.latest_created_at desc
    `;

    return rows;
  } catch (err) {
    console.error("List Support Users For Admin Error");
    throw err;
  }
}

async function listSupportTicketsByUserForAdmin(userId: string) {
  try {
    const rows = await sql`
      select
        t.ticket_id,
        t.user_id,
        t.admin_id,
        t.status,
        t.created_at,
        t.updated_at,
        t.archived_at,
        u.username as user_username,
        u.role as user_role,
        coalesce(s.firstname, tu.firstname, u.username) as user_firstname,
        coalesce(s.lastname, tu.lastname, '') as user_lastname
      from support_tickets as t
      join users as u on u.user_uuid = t.user_id
      left join students as s on s.user_uuid = t.user_id
      left join tutors as tu on tu.user_uuid = t.user_id
      where t.user_id = ${userId}
      order by t.created_at desc, t.ticket_id desc
    `;

    return rows;
  } catch (err) {
    console.error("List Support Tickets By User For Admin Error");
    throw err;
  }
}

export {
  ensureSupportTables,
  getOrCreateOpenSupportTicketForUser,
  getSupportTicketById,
  getSupportTicketDetails,
  listSupportTicketsForUser,
  listSupportMessages,
  sendSupportMessage,
  archiveSupportTicket,
  listSupportUsersForAdmin,
  listSupportTicketsByUserForAdmin,
};

