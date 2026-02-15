import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/features/groups/presentation/group_chat_screen.dart';

import '../../groups/presentation/create_group_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedTab = 0; // 0: Upcoming, 1: Past, 2: Created

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: TabBar(
            indicatorColor: const Color(0xFF7B61FF),
            labelColor: const Color(0xFF7B61FF),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Created'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingTrips(user?.id),
            _buildPastTrips(user?.id),
            _buildCreatedTrips(user?.id),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTrips(String? userId) {
    return FutureBuilder<List<Trip>>(
      future: userId != null ? _firebaseService.getTripsJoinedByUser(userId) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];
        final upcomingTrips = trips
            .where((trip) => trip.startDate.isAfter(DateTime.now()))
            .toList();

        return _buildTripList(upcomingTrips);
      },
    );
  }

  Widget _buildPastTrips(String? userId) {
    return FutureBuilder<List<Trip>>(
      future: userId != null ? _firebaseService.getTripsJoinedByUser(userId) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];
        final pastTrips = trips
            .where((trip) => trip.endDate.isBefore(DateTime.now()))
            .toList();

        return _buildTripList(pastTrips);
      },
    );
  }

  Widget _buildCreatedTrips(String? userId) {
    return FutureBuilder<List<Trip>>(
      future: userId != null ? _firebaseService.getTripsByUser(userId) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];
        return _buildTripList(trips, showHost: false);
      },
    );
  }

  Widget _buildTripList(List<Trip> trips, {bool showHost = true}) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No trips found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Join or create a trip to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Create Trip'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return TripCard(
          trip: trips[index],
          showHost: showHost,
          onChat: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                  groupId: trips[index].id,
                  groupName: trips[index].title,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final bool showHost;
  final VoidCallback onChat;

  const TripCard({
    super.key,
    required this.trip,
    this.showHost = true,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final days = trip.endDate.difference(trip.startDate).inDays;
    final seatsLeft = trip.maxMembers - trip.currentMembers;
    final isUpcoming = trip.startDate.isAfter(DateTime.now());
    final isPast = trip.endDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? Colors.blue[50]
                        : isPast
                        ? Colors.grey[200]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUpcoming
                        ? 'UPCOMING'
                        : isPast
                        ? 'COMPLETED'
                        : 'ONGOING',
                    style: TextStyle(
                      color: isUpcoming
                          ? Colors.blue[700]
                          : isPast
                          ? Colors.grey[600]
                          : Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onChat,
                  color: const Color(0xFF7B61FF),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              trip.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2B),
              ),
            ),
            const SizedBox(height: 8),
            // Destination
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  trip.destination,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• $days days',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${trip.currentMembers}/${trip.maxMembers}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: trip.currentMembers / trip.maxMembers,
                  backgroundColor: Colors.grey[200],
                  color: seatsLeft > 0 ? Colors.green : Colors.red,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      seatsLeft > 0 ? '$seatsLeft seats left' : 'Trip Full',
                      style: TextStyle(
                        fontSize: 12,
                        color: seatsLeft > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showHost)
                      Row(
                        children: [
                          Text(
                            'Host: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            trip.hostName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // View details
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7B61FF),
                      side: const BorderSide(color: Color(0xFF7B61FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Group Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}