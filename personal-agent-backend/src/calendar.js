import { getCalendar } from "./google.js";

async function primaryTimeZone(calendar) {
  try {
    const cal = await calendar.calendars.get({ calendarId: "primary" });
    return cal.data.timeZone || "UTC";
  } catch {
    return "UTC";
  }
}

function dayBounds(isoDate, timeZone) {
  return {
    start: { dateTime: `${isoDate}T00:00:00`, timeZone },
    end: { dateTime: `${isoDate}T23:59:59`, timeZone },
  };
}

export async function getCalendarEvents({ start_date, end_date }) {
  const calendar = getCalendar();
  const timeZone = await primaryTimeZone(calendar);
  const end = end_date || start_date;
  const startBound = dayBounds(start_date, timeZone).start;
  const endBound = dayBounds(end, timeZone).end;

  const res = await calendar.events.list({
    calendarId: "primary",
    timeMin: new Date(startBound.dateTime).toISOString(),
    timeMax: new Date(endBound.dateTime).toISOString(),
    singleEvents: true,
    orderBy: "startTime",
    maxResults: 50,
  });

  const events = (res.data.items || []).map((ev) => ({
    id: ev.id,
    title: ev.summary || "(no title)",
    start: ev.start?.dateTime || ev.start?.date,
    end: ev.end?.dateTime || ev.end?.date,
    attendees: (ev.attendees || []).map((a) => a.email).filter(Boolean),
    location: ev.location || "",
  }));

  return { start_date, end_date: end, timeZone, events };
}

export async function createCalendarEvent({
  title,
  date,
  start_time,
  end_time,
  attendees,
}) {
  const calendar = getCalendar();
  const timeZone = await primaryTimeZone(calendar);
  const requestBody = {
    summary: title,
    start: { dateTime: `${date}T${start_time}:00`, timeZone },
    end: { dateTime: `${date}T${end_time}:00`, timeZone },
  };
  if (attendees?.length) {
    requestBody.attendees = attendees.map((email) => ({ email }));
  }

  const created = await calendar.events.insert({
    calendarId: "primary",
    requestBody,
    sendUpdates: attendees?.length ? "all" : "none",
  });

  return {
    status: "event_created",
    event_id: created.data.id,
    htmlLink: created.data.htmlLink,
    title,
    date,
    start_time,
    end_time,
    timeZone,
    attendees: attendees || [],
  };
}
