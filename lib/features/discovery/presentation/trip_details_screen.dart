import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:provider/provider.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final days = trip.endDate.difference(trip.startDate).inDays;
    final seatsLeft = trip.maxMembers - trip.currentMembers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: trip.images.isNotEmpty
                  ? trip.images.first
                  : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5',
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Destination
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 6),
                      Text(trip.destination),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                      ),
                      const SizedBox(width: 10),
                      Text('($days days)'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Budget
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Budget: ₹${trip.budget.toInt()}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'About this trip',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(trip.description),

                  const SizedBox(height: 20),

                  // Members
                  const Text(
                    'Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('${trip.currentMembers}/${trip.maxMembers} joined'),

                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: trip.currentMembers / trip.maxMembers,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  const SizedBox(height: 20),

                  // Tags
                  Wrap(
                    spacing: 8,
                    children: trip.tags.map((tag) {
                      return Chip(label: Text(tag));
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: seatsLeft > 0
                              ? () async {
                            final service = FirebaseService();
                            final userId = service.currentUserId;
                            final auth = context.read<AuthController>();
                            final user = auth.currentUser;
                            if (userId != null) {
                              await service.joinTrip(trip.id, userId, user!.name!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joined trip!')),
                              );
                            }
                          }
                              : null,
                          child: Text(seatsLeft > 0 ? 'Join Trip' : 'Full'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
