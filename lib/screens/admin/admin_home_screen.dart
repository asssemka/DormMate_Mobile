import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Добро пожаловать, администратор!',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildStatCard(
            icon: Icons.people,
            label: '',
            value: '—',
          ),
          _buildStatCard(
            icon: Icons.chat,
            label: '',
            value: '—',
          ),
          _buildStatCard(
            icon: Icons.assignment_turned_in,
            label: '',
            value: '—',
          ),

          const SizedBox(height: 30),
          const Text(
              'Добавьте здесь графики, последние уведомления или любую\nдополнительную информацию для администратора.'),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

