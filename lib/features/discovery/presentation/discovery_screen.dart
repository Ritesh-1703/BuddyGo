import 'package:buddygoapp/features/discovery/presentation/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/features/groups/presentation/create_group_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/presentation/auth_controller.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Upcoming',
    'Popular',
    'Nearby',
    'Budget',
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced Search Bar with Neon Glow
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0F2FE), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF1A202C),
                ),
                decoration: InputDecoration(
                  hintText: 'Search destinations or trips...',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFFA0AEC0),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFFA0AEC0),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),

          // Enhanced Filter Chips with Color Burst
          SliverToBoxAdapter(
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  // Different colors for different filters
                  Color getFilterColor() {
                    if (!isSelected) return const Color(0xFF8B5CF6);
                    switch (index) {
                      case 0:
                        return const Color(0xFF8B5CF6); // Purple
                      case 1:
                        return const Color(0xFFFF6B6B); // Coral
                      case 2:
                        return const Color(0xFF4FD1C5); // Teal
                      case 3:
                        return const Color(0xFFFBBF24); // Yellow
                      case 4:
                        return const Color(0xFF9F7AEA); // Lavender
                      default:
                        return const Color(0xFF8B5CF6);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : getFilterColor(),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: getFilterColor(),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : getFilterColor().withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: isSelected ? 4 : 0,
                      shadowColor: getFilterColor().withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),
          ),

          // Enhanced Create Trip Card with Gradient & Glow
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFFF6B6B),
                        Color(0xFFFBBF24),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(5, 5),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Animated Icon Container
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.elasticOut,
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: 0.9 + (value * 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF8B5CF6),
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Your Trip',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plan a trip and find travel buddies',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Real-time Trips List with Enhanced Cards
          SliverToBoxAdapter(
            child: StreamBuilder<List<Trip>>(
              stream: _firebaseService.getTripsStreamWithFilter(
                _selectedFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFFF6B6B),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading trips',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final trips = snapshot.data ?? [];

                // Apply search filter locally
                final query = _searchController.text.toLowerCase();
                final filteredTrips = trips.where((trip) {
                  return trip.title.toLowerCase().contains(query) ||
                      trip.destination.toLowerCase().contains(query);
                }).toList();

                if (filteredTrips.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9D8FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.travel_explore,
                            size: 64,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trips found',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing filters or search',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF718096),
                          ),
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
                    return EnhancedTripCard(trip: filteredTrips[index]);
                  },
                );
              },
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class EnhancedTripCard extends StatelessWidget {
  final Trip trip;

  const EnhancedTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final days = trip.endDate.difference(trip.startDate).inDays;
    final seatsLeft = trip.maxMembers - trip.currentMembers;
    final percentage = trip.currentMembers / trip.maxMembers;
    final currentUserId = firebaseService.currentUserId;
    final isHost = currentUserId == trip.hostId;
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(trip: trip),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with Enhanced Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: trip.images.isNotEmpty
                          ? trip.images.first
                          : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE9D8FD), Color(0xFFFFE5E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE5E5), Color(0xFFFFD1D1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Destination Badge with Modern Design
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            screenWidth * 0.5, // Limit width to 50% of screen
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFFFF6B6B),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              trip.destination,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1A202C),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Budget Badge with Neon Style
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FD1C5), Color(0xFF06D6A0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FD1C5).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹${trip.budget.toInt()}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with overflow handling
                    Text(
                      trip.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A202C),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Host Info with Enhanced Design
                    FutureBuilder(
                      future: firebaseService.getUserProfile(trip.hostId),
                      builder: (context, snapshot) {
                        final host = snapshot.data;
                        return Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.7, // Limit width
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: host?.photoUrl != null
                                    ? CachedNetworkImageProvider(
                                        host!.photoUrl!,
                                      )
                                    : null,
                                backgroundColor: const Color(
                                  0xFF8B5CF6,
                                ).withOpacity(0.1),
                                child: host?.photoUrl == null
                                    ? Text(
                                        host?.name?[0] ?? '?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Hosted by ${host?.name ?? trip.hostName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF4A5568),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date Section with Icons - Fixed overflow
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE9D8FD), Color(0xFFD6BCFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd').format(trip.endDate)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A202C),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                '$days ${days == 1 ? 'day' : 'days'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Members Progress with Enhanced Design
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trip Members',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                            Text(
                              '${trip.currentMembers}/${trip.maxMembers}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A202C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2FE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: seatsLeft > 0
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF4FD1C5),
                                            Color(0xFF06D6A0),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B6B),
                                            Color(0xFFE53E3E),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: seatsLeft > 0
                                          ? const Color(
                                              0xFF4FD1C5,
                                            ).withOpacity(0.3)
                                          : const Color(
                                              0xFFFF6B6B,
                                            ).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              seatsLeft > 0 ? Icons.people : Icons.warning,
                              size: 14,
                              color: seatsLeft > 0
                                  ? const Color(0xFF4FD1C5)
                                  : const Color(0xFFFF6B6B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                seatsLeft > 0
                                    ? '$seatsLeft ${seatsLeft == 1 ? 'spot' : 'spots'} left'
                                    : 'Trip is full',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: seatsLeft > 0
                                      ? const Color(0xFF4FD1C5)
                                      : const Color(0xFFFF6B6B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (seatsLeft > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4FD1C5,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Join now!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4FD1C5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons with Enhanced Design
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TripDetailsScreen(trip: trip),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5CF6),
                              side: const BorderSide(
                                color: Color(0xFF8B5CF6),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Details'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // In EnhancedTripCard build method

                        // Then update the ElevatedButton:
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                seatsLeft > 0 &&
                                    !isHost // ✅ Add isHost check here
                                ? () async {
                                    final userId =
                                        firebaseService.currentUserId;
                                    final auth = context.read<AuthController>();
                                    final user = auth.currentUser;
                                    if (userId != null && user != null) {
                                      try {
                                        await firebaseService.joinTrip(
                                          trip.id,
                                          userId,
                                          user.name!,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Successfully joined the trip!',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(
                                                0xFF4FD1C5,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString().substring(0, e.toString().length > 30 ? 30 : e.toString().length)}...',
                                                style: GoogleFonts.poppins(),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              backgroundColor: const Color(
                                                0xFFFF6B6B,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                : null, // Disabled if no seats left OR user is host
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  seatsLeft > 0 &&
                                      !isHost // ✅ Different color if host
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFFA0AEC0),
                              foregroundColor: Colors.white,
                              elevation: seatsLeft > 0 && !isHost ? 8 : 0,
                              shadowColor: const Color(
                                0xFF8B5CF6,
                              ).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isHost
                                    ? "Your Trip" // ✅ Show "Your Trip" instead of Join
                                    : (seatsLeft > 0 ? 'Join Now' : 'Waitlist'),
                              ),
                            ),
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
      ),
    );
  }
}
