import 'package:buddygoapp/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buddygoapp/features/discovery/data/trip_model.dart';
import 'package:buddygoapp/core/services/firebase_service.dart';
import 'package:provider/provider.dart';

// ==================== CONSTANTS ====================
class TripColors {
  static const Color primary = Color(0xFF8B5CF6);     // Purple
  static const Color secondary = Color(0xFFFF6B6B);   // Coral
  static const Color tertiary = Color(0xFF4FD1C5);    // Teal
  static const Color accent = Color(0xFFFBBF24);      // Yellow
  static const Color lavender = Color(0xFF9F7AEA);    // Lavender
  static const Color success = Color(0xFF06D6A0);     // Mint Green
  static const Color error = Color(0xFFFF6B6B);       // Coral for errors
  static const Color background = Color(0xFFF0F2FE);  // Light purple tint
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
}

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final days = trip.endDate.difference(trip.startDate).inDays;
    final seatsLeft = trip.maxMembers - trip.currentMembers;
    final percentage = trip.currentMembers / trip.maxMembers;
    final firebaseService = FirebaseService();
    final currentUserId = firebaseService.currentUserId;
    final isHost = currentUserId == trip.hostId;
    return Scaffold(
      backgroundColor: TripColors.background,
      body: CustomScrollView(
        slivers: [
          // Enhanced Sliver App Bar with Parallax Effect
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            floating: false,
            backgroundColor: TripColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: TripColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  CachedNetworkImage(
                    imageUrl: trip.images.isNotEmpty
                        ? trip.images.first
                        : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: TripColors.background,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(TripColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: TripColors.background,
                      child: Icon(Icons.broken_image, size: 64, color: TripColors.textSecondary),
                    ),
                  ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Destination Badge
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          const Icon(Icons.location_on, color: TripColors.secondary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            trip.destination,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: TripColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Budget Badge
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [TripColors.tertiary, TripColors.success],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: TripColors.tertiary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                          Text(
                            '${trip.budget.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with gradient effect
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [TripColors.primary, TripColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        trip.title,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Host Info
                    FutureBuilder(
                      future: FirebaseService().getUserProfile(trip.hostId),
                      builder: (context, snapshot) {
                        final host = snapshot.data;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: TripColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [TripColors.primary, TripColors.secondary],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white,
                                  backgroundImage: host?.photoUrl != null
                                      ? CachedNetworkImageProvider(host!.photoUrl!)
                                      : null,
                                  child: host?.photoUrl == null
                                      ? Text(
                                    host?.name?[0] ?? trip.hostName[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: TripColors.primary,
                                    ),
                                  )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hosted by',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: TripColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      host?.name ?? trip.hostName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: TripColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Container(
                              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              //   decoration: BoxDecoration(
                              //     color: TripColors.primary.withOpacity(0.1),
                              //     borderRadius: BorderRadius.circular(20),
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       const Icon(Icons.star, color: TripColors.accent, size: 16),
                              //       const SizedBox(width: 4),
                              //       Text(
                              //         '4.8',
                              //         style: GoogleFonts.poppins(
                              //           fontSize: 14,
                              //           fontWeight: FontWeight.w600,
                              //           color: TripColors.primary,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Info Cards
                    Row(
                      children: [
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Duration',
                          value: '$days days',
                          color: TripColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          icon: Icons.people,
                          title: 'Members',
                          value: '${trip.currentMembers}/${trip.maxMembers}',
                          color: TripColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          icon: Icons.event_available,
                          title: 'Seats Left',
                          value: seatsLeft.toString(),
                          color: seatsLeft > 0 ? TripColors.success : TripColors.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            TripColors.primary.withOpacity(0.05),
                            TripColors.secondary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Trip Capacity',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: TripColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${(percentage * 100).toInt()}% Full',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: percentage > 0.7 ? TripColors.error : TripColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: TripColors.border,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: percentage > 0.7
                                          ? [TripColors.error, TripColors.secondary]
                                          : [TripColors.primary, TripColors.tertiary],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (percentage > 0.7 ? TripColors.error : TripColors.primary).withOpacity(0.3),
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
                                seatsLeft > 0 ? Icons.info_outline : Icons.warning,
                                size: 14,
                                color: seatsLeft > 0 ? TripColors.success : TripColors.error,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  seatsLeft > 0
                                      ? 'Hurry! Only $seatsLeft ${seatsLeft == 1 ? 'spot' : 'spots'} left'
                                      : 'This trip is full - Join waitlist',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: seatsLeft > 0 ? TripColors.success : TripColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    _buildSectionTitle('About This Trip'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TripColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip.description,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: TripColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tags Section
                    _buildSectionTitle('Trip Highlights'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: trip.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getTagColor(tag).withOpacity(0.1),
                                _getTagColor(tag).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getTagColor(tag).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTagIcon(tag),
                                size: 14,
                                color: _getTagColor(tag),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _getTagColor(tag),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TripColors.primary,
                              side: const BorderSide(color: TripColors.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: seatsLeft > 0 && !isHost  //  Add isHost check
                                ? () async {
                              final service = FirebaseService();
                              final userId = service.currentUserId;
                              final auth = context.read<AuthController>();
                              final user = auth.currentUser;

                              if (userId != null && user != null) {
                                try {
                                  await service.joinTrip(trip.id, userId, user.name!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Successfully joined the trip!',
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: TripColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error: ${e.toString()}',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: TripColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: seatsLeft > 0 && !isHost
                                  ? TripColors.primary
                                  : TripColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              elevation: seatsLeft > 0 && !isHost ? 8 : 0,
                              shadowColor: TripColors.primary.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isHost
                                      ? Icons.person
                                      : (seatsLeft > 0 ? Icons.flight_takeoff : Icons.warning),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    isHost
                                        ? 'Your Trip'
                                        : (seatsLeft > 0 ? 'Join Now' : 'Trip Full')
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Safety Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TripColors.lavender.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TripColors.lavender.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security,
                              color: TripColors.lavender,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Safety First',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TripColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Meet in public places and share your location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: TripColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: TripColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [TripColors.primary, TripColors.secondary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TripColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'adventure':
        return TripColors.primary;
      case 'beach':
        return TripColors.tertiary;
      case 'trekking':
      case 'hiking':
        return TripColors.success;
      case 'cultural':
        return TripColors.accent;
      case 'budget':
        return TripColors.secondary;
      case 'luxury':
        return TripColors.lavender;
      default:
        return TripColors.primary;
    }
  }

  IconData _getTagIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'adventure':
        return Icons.directions_bike;
      case 'beach':
        return Icons.beach_access;
      case 'trekking':
      case 'hiking':
        return Icons.hiking;
      case 'cultural':
        return Icons.museum;
      case 'budget':
        return Icons.attach_money;
      case 'luxury':
        return Icons.star;
      default:
        return Icons.tag;
    }
  }
}