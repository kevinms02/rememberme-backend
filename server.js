// Backend RememberME (Node.js/Express/MongoDB)
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

mongoose.connect('mongodb://localhost:27017/rememberme', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// User Schema
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  username: { type: String, unique: true },
  password: String,
  profilePic: String,
});
const User = mongoose.model('User', userSchema);

// Memory Schema
const memorySchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  title: String,
  photos: [String],
  date: String,
  notes: String,
  createdAt: { type: Date, default: Date.now },
});
const Memory = mongoose.model('Memory', memorySchema);

// Auth: Login
app.post('/api/login', async (req, res) => {
  console.log('POST /api/login called', req.body); // Debug log
  const { username, password } = req.body;
  const user = await User.findOne({ username, password });
  if (!user) return res.status(401).json({ message: 'Login gagal' });
  res.json({ user });
});

// Auth: Sign Up
app.post('/api/signup', async (req, res) => {
  console.log('POST /api/signup called', req.body); // Debug log
  const { name, email, username, password } = req.body;
  try {
    const user = new User({ name, email, username, password });
    await user.save();
    res.json({ user });
  } catch (e) {
    res.status(400).json({ message: 'Username sudah terdaftar' });
  }
});

// Get Memories
app.get('/api/memories/:userId', async (req, res) => {
  console.log('GET /api/memories/:userId called', req.params.userId); // Debug log
  const memories = await Memory.find({ userId: req.params.userId });
  res.json({ memories });
});

// Create Memory
app.post('/api/memories', async (req, res) => {
  console.log('POST /api/memories called', req.body); // Debug log
  const { userId, title, photos, date, notes } = req.body;
  const memory = new Memory({ userId, title, photos, date, notes });
  await memory.save();
  res.json({ memory });
});

// Update Memory
app.put('/api/memories/:id', async (req, res) => {
  console.log('PUT /api/memories/:id called', req.params.id, req.body); // Debug log
  const { title, photos, date, notes } = req.body;
  const memory = await Memory.findByIdAndUpdate(
    req.params.id,
    { title, photos, date, notes },
    { new: true }
  );
  res.json({ memory });
});

// Delete Memory
app.delete('/api/memories/:id', async (req, res) => {
  console.log('DELETE /api/memories/:id called', req.params.id); // Debug log
  await Memory.findByIdAndDelete(req.params.id);
  res.json({ success: true });
});

// Update Profile
app.put('/api/user/:id', async (req, res) => {
  console.log('PUT /api/user/:id called', req.params.id, req.body); // Debug log
  const { name, email, username, profilePic } = req.body;
  const user = await User.findByIdAndUpdate(
    req.params.id,
    { name, email, username, profilePic },
    { new: true }
  );
  res.json({ user });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => console.log('Server running on port', PORT));
