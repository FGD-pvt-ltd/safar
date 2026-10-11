
const stops = [
  { id: "TAMBARAM", name: "Tambaram" },
  { id: "GUINDY", name: "Guindy" },
  { id: "EGMORE", name: "Chennai Egmore" },
  { id: "CENTRAL", name: "Chennai Central" }
];

const connections = [
  {
    from: "TAMBARAM",
    to: "GUINDY",
    durationMinutes: 20,
    mode: "train",
    service: "Sample suburban train",
    fare: 10,
    bidirectional: true
  },
  {
    from: "GUINDY",
    to: "EGMORE",
    durationMinutes: 15,
    mode: "train",
    service: "Sample suburban train",
    fare: 10,
    bidirectional: true
  },
  {
    from: "EGMORE",
    to: "CENTRAL",
    durationMinutes: 10,
    mode: "train",
    service: "Sample suburban train",
    fare: 5,
    bidirectional: true
  },
  {
    from: "TAMBARAM",
    to: "EGMORE",
    durationMinutes: 45,
    mode: "bus",
    service: "Sample bus",
    fare: 20,
    bidirectional: true
  },
  {
    from: "GUINDY",
    to: "CENTRAL",
    durationMinutes: 35,
    mode: "bus",
    service: "Sample bus",
    fare: 20,
    bidirectional: true
  }
];

module.exports = { stops, connections };
