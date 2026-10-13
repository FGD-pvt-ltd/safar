
const stops = [
  { id: "TAMBARAM", name: "Tambaram" },
  { id: "CHROMEPET", name: "Chromepet" },
  { id: "PALLAVARAM", name: "Pallavaram" },
  { id: "AIRPORT", name: "Chennai Airport" },
  { id: "GUINDY", name: "Guindy" },
  { id: "SAIDAPET", name: "Saidapet" },
  { id: "T_NAGAR", name: "T. Nagar" },
  { id: "VELACHERY", name: "Velachery" },
  { id: "ALANDUR", name: "Alandur" },
  { id: "KOYAMBEDU", name: "Koyambedu" },
  { id: "ANNA_NAGAR", name: "Anna Nagar" },
  { id: "EGMORE", name: "Chennai Egmore" },
  { id: "CENTRAL", name: "Chennai Central" },
  { id: "BROADWAY", name: "Broadway" },
  { id: "BEACH", name: "Chennai Beach" },
  { id: "PERUNGUDI", name: "Perungudi" }
];

const connections = [
  { id: "C1", from: "TAMBARAM", to: "GUINDY", durationMinutes: 20, mode: "train", fare: 10, bidirectional: true },
  { id: "C2", from: "GUINDY", to: "EGMORE", durationMinutes: 15, mode: "train", fare: 10, bidirectional: true },
  { id: "C3", from: "EGMORE", to: "CENTRAL", durationMinutes: 10, mode: "train", fare: 5, bidirectional: true },
  { id: "C4", from: "TAMBARAM", to: "EGMORE", durationMinutes: 45, mode: "bus", fare: 20, bidirectional: true },
  { id: "C5", from: "GUINDY", to: "CENTRAL", durationMinutes: 35, mode: "bus", fare: 20, bidirectional: true },
  { id: "C6", from: "GUINDY", to: "SAIDAPET", durationMinutes: 8, mode: "train", fare: 5, bidirectional: true },
  { id: "C7", from: "SAIDAPET", to: "CENTRAL", durationMinutes: 28, mode: "bus", fare: 15, bidirectional: true },
  { id: "C8", from: "TAMBARAM", to: "VELACHERY", durationMinutes: 30, mode: "bus", fare: 18, bidirectional: true },
  { id: "C9", from: "VELACHERY", to: "GUINDY", durationMinutes: 12, mode: "bus", fare: 10, bidirectional: true },
  { id: "C10", from: "TAMBARAM", to: "CHROMEPET", durationMinutes: 6, mode: "train", fare: 5, bidirectional: true },
  { id: "C11", from: "CHROMEPET", to: "PALLAVARAM", durationMinutes: 5, mode: "train", fare: 5, bidirectional: true },
  { id: "C12", from: "PALLAVARAM", to: "GUINDY", durationMinutes: 14, mode: "train", fare: 5, bidirectional: true },
  { id: "C13", from: "EGMORE", to: "BEACH", durationMinutes: 12, mode: "train", fare: 5, bidirectional: true },
  { id: "C14", from: "BEACH", to: "CENTRAL", durationMinutes: 8, mode: "train", fare: 5, bidirectional: true },
  { id: "C15", from: "GUINDY", to: "ALANDUR", durationMinutes: 10, mode: "metro", fare: 10, bidirectional: true },
  { id: "C16", from: "ALANDUR", to: "AIRPORT", durationMinutes: 12, mode: "metro", fare: 10, bidirectional: true },
  { id: "C17", from: "ALANDUR", to: "KOYAMBEDU", durationMinutes: 18, mode: "metro", fare: 15, bidirectional: true },
  { id: "C18", from: "KOYAMBEDU", to: "ANNA_NAGAR", durationMinutes: 10, mode: "metro", fare: 10, bidirectional: true },
  { id: "C19", from: "SAIDAPET", to: "T_NAGAR", durationMinutes: 12, mode: "bus", fare: 10, bidirectional: true },
  { id: "C20", from: "T_NAGAR", to: "CENTRAL", durationMinutes: 25, mode: "bus", fare: 15, bidirectional: true },
  { id: "C21", from: "VELACHERY", to: "PERUNGUDI", durationMinutes: 12, mode: "bus", fare: 10, bidirectional: true },
  { id: "C22", from: "PERUNGUDI", to: "GUINDY", durationMinutes: 20, mode: "bus", fare: 15, bidirectional: true },
  { id: "C23", from: "PALLAVARAM", to: "AIRPORT", durationMinutes: 15, mode: "bus", fare: 10, bidirectional: true },
  { id: "C24", from: "CENTRAL", to: "BROADWAY", durationMinutes: 10, mode: "bus", fare: 10, bidirectional: true },
  { id: "C25", from: "EGMORE", to: "T_NAGAR", durationMinutes: 20, mode: "bus", fare: 15, bidirectional: true },
  { id: "C26", from: "GUINDY", to: "T_NAGAR", durationMinutes: 18, mode: "bus", fare: 12, bidirectional: true },
  { id: "C27", from: "AIRPORT", to: "KOYAMBEDU", durationMinutes: 30, mode: "bus", fare: 20, bidirectional: true },
  { id: "C28", from: "ANNA_NAGAR", to: "CENTRAL", durationMinutes: 25, mode: "bus", fare: 15, bidirectional: true },
  { id: "C29", from: "TAMBARAM", to: "SAIDAPET", durationMinutes: 25, mode: "bus", fare: 15, bidirectional: true },
  { id: "C30", from: "VELACHERY", to: "T_NAGAR", durationMinutes: 25, mode: "bus", fare: 15, bidirectional: true }
];

module.exports = { stops, connections };
