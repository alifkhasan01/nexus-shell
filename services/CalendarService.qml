pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton service untuk manage calendar events, notes, dan holidays
Singleton {
    id: root

    // ── Storage paths ──────────────────────────────────────────────────────
    readonly property string eventsPath: `${Quickshell.env("HOME")}/.config/quickshell/data/calendar-events.json`
    readonly property string notesPath: `${Quickshell.env("HOME")}/.config/quickshell/data/calendar-notes.json`

    // ── Data models ────────────────────────────────────────────────────────
    property var events: ({})      // { "2026-08-10": [{id, title, time, color}] }
    property var notes: ({})       // { "2026-08-10": "note text" }
    property var holidays: ({})    // { "2026-08-17": "Hari Kemerdekaan RI" }

    // Custom signals
    signal dataChanged()

    // ── Initialization ─────────────────────────────────────────────────────
    Component.onCompleted: {
        loadEvents()
        loadNotes()
        loadHolidays()
    }

    // ── Holiday data (Indonesian National Holidays) ───────────────────────
    function loadHolidays() {
        holidays = {
            // 2024
            "2024-01-01": "Tahun Baru Masehi",
            "2024-02-08": "Isra Mi'raj Nabi Muhammad SAW",
            "2024-02-10": "Tahun Baru Imlek",
            "2024-02-14": "Pilpres 2024",
            "2024-03-11": "Hari Suci Nyepi",
            "2024-03-29": "Wafat Isa Al-Masih",
            "2024-03-31": "Hari Paskah",
            "2024-04-11": "Hari Raya Idul Fitri",
            "2024-04-12": "Hari Raya Idul Fitri",
            "2024-05-01": "Hari Buruh Internasional",
            "2024-05-09": "Kenaikan Isa Al-Masih",
            "2024-05-23": "Hari Raya Waisak",
            "2024-06-01": "Hari Lahir Pancasila",
            "2024-06-17": "Hari Raya Idul Adha",
            "2024-07-07": "Tahun Baru Islam 1446 H",
            "2024-08-17": "Hari Kemerdekaan RI",
            "2024-09-16": "Maulid Nabi Muhammad SAW",
            "2024-12-25": "Hari Raya Natal",

            // 2025
            "2025-01-01": "Tahun Baru Masehi",
            "2025-01-29": "Tahun Baru Imlek",
            "2025-02-27": "Isra Mi'raj Nabi Muhammad SAW",
            "2025-03-14": "Hari Suci Nyepi",
            "2025-03-31": "Hari Raya Idul Fitri",
            "2025-04-01": "Hari Raya Idul Fitri",
            "2025-04-18": "Wafat Isa Al-Masih",
            "2025-04-20": "Hari Paskah",
            "2025-05-01": "Hari Buruh Internasional",
            "2025-05-12": "Hari Raya Waisak",
            "2025-05-29": "Kenaikan Isa Al-Masih",
            "2025-06-01": "Hari Lahir Pancasila",
            "2025-06-07": "Hari Raya Idul Adha",
            "2025-06-27": "Tahun Baru Islam 1447 H",
            "2025-08-17": "Hari Kemerdekaan RI",
            "2025-09-05": "Maulid Nabi Muhammad SAW",
            "2025-12-25": "Hari Raya Natal",

            // 2026
            "2026-01-01": "Tahun Baru Masehi",
            "2026-02-17": "Tahun Baru Imlek",
            "2026-02-16": "Isra Mi'raj Nabi Muhammad SAW",
            "2026-03-03": "Hari Suci Nyepi",
            "2026-03-20": "Hari Raya Idul Fitri",
            "2026-03-21": "Hari Raya Idul Fitri",
            "2026-04-03": "Wafat Isa Al-Masih",
            "2026-04-05": "Hari Paskah",
            "2026-05-01": "Hari Buruh Internasional",
            "2026-05-02": "Hari Raya Waisak",
            "2026-05-14": "Kenaikan Isa Al-Masih",
            "2026-05-27": "Hari Raya Idul Adha",
            "2026-06-01": "Hari Lahir Pancasila",
            "2026-06-16": "Tahun Baru Islam 1448 H",
            "2026-08-17": "Hari Kemerdekaan RI",
            "2026-08-26": "Maulid Nabi Muhammad SAW",
            "2026-12-25": "Hari Raya Natal",

            // 2027
            "2027-01-01": "Tahun Baru Masehi",
            "2027-02-06": "Tahun Baru Imlek",
            "2027-02-06": "Isra Mi'raj Nabi Muhammad SAW",
            "2027-03-09": "Hari Raya Idul Fitri",
            "2027-03-10": "Hari Raya Idul Fitri",
            "2027-03-23": "Hari Suci Nyepi",
            "2027-03-26": "Wafat Isa Al-Masih",
            "2027-03-28": "Hari Paskah",
            "2027-04-21": "Hari Raya Waisak",
            "2027-05-01": "Hari Buruh Internasional",
            "2027-05-06": "Kenaikan Isa Al-Masih",
            "2027-05-16": "Hari Raya Idul Adha",
            "2027-06-01": "Hari Lahir Pancasila",
            "2027-06-06": "Tahun Baru Islam 1449 H",
            "2027-08-15": "Maulid Nabi Muhammad SAW",
            "2027-08-17": "Hari Kemerdekaan RI",
            "2027-12-25": "Hari Raya Natal"
        }
    }

    // ── Events CRUD ────────────────────────────────────────────────────────
    function addEvent(year, month, day, title, time, color) {
        const dateKey = formatDateKey(year, month, day)
        if (!events[dateKey]) events[dateKey] = []
        
        const event = {
            id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
            title: title,
            time: time || "",
            color: color || "#89b4fa"  // catppuccin blue default
        }
        
        events[dateKey].push(event)
        events = Object.assign({}, events)   // trigger notif biar UI refresh
        saveEvents()
        dataChanged()
    }

    function removeEvent(year, month, day, eventId) {
        const dateKey = formatDateKey(year, month, day)
        if (!events[dateKey]) return
        
        events[dateKey] = events[dateKey].filter(e => e.id !== eventId)
        if (events[dateKey].length === 0) delete events[dateKey]
        
        events = Object.assign({}, events)   // trigger notif biar UI refresh
        saveEvents()
        dataChanged()
    }

    function getEvents(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return events[dateKey] || []
    }

    function hasEvents(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return events[dateKey] && events[dateKey].length > 0
    }

    // ── Notes CRUD ─────────────────────────────────────────────────────────
    function setNote(year, month, day, noteText) {
        const dateKey = formatDateKey(year, month, day)
        if (noteText && noteText.trim() !== "") {
            notes[dateKey] = noteText
        } else {
            delete notes[dateKey]
        }
        notes = Object.assign({}, notes)   // trigger notif biar UI refresh
        saveNotes()
        dataChanged()
    }

    function getNote(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return notes[dateKey] || ""
    }

    function hasNote(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return notes[dateKey] && notes[dateKey].trim() !== ""
    }

    // ── Holidays ───────────────────────────────────────────────────────────
    function getHoliday(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return holidays[dateKey] || ""
    }

    function isHoliday(year, month, day) {
        const dateKey = formatDateKey(year, month, day)
        return holidays[dateKey] !== undefined
    }

    // ── Persistence ────────────────────────────────────────────────────────
    // Proses baca file (async, hasil diproses di onStreamFinished)
    property Process _loadEventsProc: Process {
        command: ["sh", "-c", `cat '${eventsPath}' 2>/dev/null || echo ''`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim()
                if (out === "") {
                    events = {}
                    return
                }
                try {
                    events = JSON.parse(out)
                    events = Object.assign({}, events)
                    console.log("Events loaded:", Object.keys(events).length, "dates")
                } catch (e) {
                    console.log("No events file found or error loading, starting fresh")
                    events = {}
                }
            }
        }
    }

    property Process _loadNotesProc: Process {
        command: ["sh", "-c", `cat '${notesPath}' 2>/dev/null || echo ''`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim()
                if (out === "") {
                    notes = {}
                    return
                }
                try {
                    notes = JSON.parse(out)
                    notes = Object.assign({}, notes)
                    console.log("Notes loaded:", Object.keys(notes).length, "dates")
                } catch (e) {
                    console.log("No notes file found or error loading, starting fresh")
                    notes = {}
                }
            }
        }
    }

    // Proses tulis file (jalankan dengan set running = true)
    property Process _saveEventsProc: Process { command: [""] }
    property Process _saveNotesProc: Process { command: [""] }

    function saveEvents() {
        try {
            const data = JSON.stringify(events, null, 2)
            _saveEventsProc.command = [
                "sh", "-c",
                `cat > '${eventsPath}' << 'QSCAL_DATA_EOF'\n${data}\nQSCAL_DATA_EOF`
            ]
            _saveEventsProc.running = true
            console.log("Events saved:", Object.keys(events).length, "dates")
        } catch (e) {
            console.error("Failed to save events:", e)
        }
    }

    function loadEvents() {
        _loadEventsProc.running = true
    }

    function saveNotes() {
        try {
            const data = JSON.stringify(notes, null, 2)
            _saveNotesProc.command = [
                "sh", "-c",
                `cat > '${notesPath}' << 'QSCAL_DATA_EOF'\n${data}\nQSCAL_DATA_EOF`
            ]
            _saveNotesProc.running = true
            console.log("Notes saved:", Object.keys(notes).length, "dates")
        } catch (e) {
            console.error("Failed to save notes:", e)
        }
    }

    function loadNotes() {
        _loadNotesProc.running = true
    }

    // ── Utility ────────────────────────────────────────────────────────────
    function formatDateKey(year, month, day) {
        const m = (month + 1).toString().padStart(2, '0')
        const d = day.toString().padStart(2, '0')
        return `${year}-${m}-${d}`
    }

    // ── Week Number (ISO 8601) ─────────────────────────────────────────────
    function getWeekNumber(year, month, day) {
        const date = new Date(year, month, day)
        const thursday = new Date(date.getTime())
        thursday.setDate(date.getDate() - ((date.getDay() + 6) % 7) + 3)
        const yearStart = new Date(thursday.getFullYear(), 0, 1)
        const weekNo = Math.ceil((((thursday - yearStart) / 86400000) + 1) / 7)
        return weekNo
    }

    // ── Hijri Conversion (Simplified) ──────────────────────────────────────
    function toHijri(year, month, day) {
        // Simplified Hijri conversion using approximation
        // Based on: Hijri = (Gregorian - 622) * 1.03 roughly
        const gregorianDate = new Date(year, month, day)
        const julianDay = Math.floor(gregorianDate.getTime() / 86400000) + 2440588
        
        // Simple algorithm (not 100% accurate, for display only)
        const hijriJulianDay = julianDay - 1948440
        const hijriYear = Math.floor((30 * hijriJulianDay + 10646) / 10631)
        const hijriMonth = Math.ceil((hijriJulianDay - 29.5 - Math.floor((hijriYear - 1) * 354.36667)) / 29.5)
        const hijriDay = hijriJulianDay - Math.floor(29.5 * (hijriMonth - 1)) - Math.floor((hijriYear - 1) * 354.36667) + 1
        
        const monthNames = [
            "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
            "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
            "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
        ]
        
        const adjustedMonth = Math.max(1, Math.min(12, Math.floor(hijriMonth)))
        const adjustedDay = Math.max(1, Math.floor(hijriDay))
        
        return {
            day: adjustedDay,
            month: adjustedMonth,
            year: Math.floor(hijriYear),
            monthName: monthNames[adjustedMonth - 1] || "Muharram"
        }
    }

    // ── Statistics ─────────────────────────────────────────────────────────
    function getMonthStats(year, month) {
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        let workDays = 0
        let weekendDays = 0
        let holidayCount = 0
        let eventsCount = 0
        
        for (let day = 1; day <= daysInMonth; day++) {
            const date = new Date(year, month, day)
            const dayOfWeek = date.getDay()
            
            if (dayOfWeek === 0 || dayOfWeek === 6) {
                weekendDays++
            } else {
                workDays++
            }
            
            if (isHoliday(year, month, day)) {
                holidayCount++
            }
            
            if (hasEvents(year, month, day)) {
                eventsCount += getEvents(year, month, day).length
            }
        }
        
        return {
            totalDays: daysInMonth,
            workDays: workDays,
            weekendDays: weekendDays,
            holidays: holidayCount,
            events: eventsCount
        }
    }
}
