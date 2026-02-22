import 'package:buddygoapp/features/discovery/presentation/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';

import '../../auth/presentation/auth_controller.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Upcoming', 'Popular', 'Nearby', 'Budget'];
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search destinations or trips...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  // Implement search
                },
              ),
            ),
          ),
          // Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: const Color(0xFF7B61FF),
                      labelStyle: TextStyle(
                        color: _selectedFilter == filter
                            ? Colors.white
                            : const Color(0xFF6E7A8A),
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Create Trip Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF9E8AFF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF7B61FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Your Trip',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plan a trip and find travel buddies',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Real-time Trips List
          SliverToBoxAdapter(
            child: StreamBuilder<List<Trip>>(
              stream: _firebaseService.getTripsStreamWithFilter(_selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Error loading trips')),
                  );
                }

                final trips = snapshot.data ?? [];

                // 🔍 Apply search filter locally
                final query = _searchController.text.toLowerCase();
                final filteredTrips = trips.where((trip) {
                  return trip.title.toLowerCase().contains(query) ||
                      trip.destination.toLowerCase().contains(query);
                }).toList();

                if (filteredTrips.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.travel_explore, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No trips found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try changing filters or search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) {
                    return TripCard(trip: filteredTrips[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final days = trip.endDate.difference(trip.startDate).inDays;
    final seatsLeft = trip.maxMembers - trip.currentMembers;
    final percentage = trip.currentMembers / trip.maxMembers;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to trip details
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: trip.images.isNotEmpty
                        ? trip.images.first
                        : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // Destination Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Host
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D2B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder(
                              future: firebaseService.getUserProfile(trip.hostId),
                              builder: (context, snapshot) {
                                final host = snapshot.data;
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage: host?.photoUrl != null
                                          ? CachedNetworkImageProvider(host!.photoUrl!)
                                          : null,
                                      child: host?.photoUrl == null
                                          ? Text(host?.name?[0] ?? '?')
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'By ${host?.name ?? trip.hostName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6E7A8A),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Budget
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${trip.budget.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dates
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF7B61FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd').format(trip.endDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D2B),
                            ),
                          ),
                          Text(
                            '$days days',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E7A8A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Members Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Members',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6E7A8A),
                            ),
                          ),
                          Text(
                            '${trip.currentMembers}/${trip.maxMembers}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D2B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: const Color(0xFFF8F9FF),
                        color: seatsLeft > 0
                            ? const Color(0xFF00D4AA)
                            : const Color(0xFFFF647C),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            seatsLeft > 0 ? '$seatsLeft seats left' : 'Trip Full',
                            style: TextStyle(
                              fontSize: 12,
                              color: seatsLeft > 0
                                  ? const Color(0xFF00D4AA)
                                  : const Color(0xFFFF647C),
                              fontWeight: FontWeight.w600,
                            ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailsScreen(trip: trip),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7B61FF),
                            side: const BorderSide(
                              color: Color(0xFF7B61FF),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: seatsLeft > 0
                              ? () async {
                            final userId = firebaseService.currentUserId;
                            final auth = context.read<AuthController>();
                            final user = auth.currentUser;
                            if (userId != null) {
                              await firebaseService.joinTrip(trip.id, userId, user!.name!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Successfully joined the trip!'),
                                  backgroundColor: Color(0xFF00D4AA),
                                ),
                              );
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: seatsLeft > 0
                                ? const Color(0xFF7B61FF)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(seatsLeft > 0 ? 'Join Trip' : 'Waitlist'),
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