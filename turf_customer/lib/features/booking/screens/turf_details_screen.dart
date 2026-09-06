import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/review_provider.dart';
import '../../../models/turf_model.dart';
import '../../../models/review_model.dart';
import 'booking_summary_screen.dart';
import '../../home/widgets/turf_type_badge.dart';

class TurfDetailsScreen extends StatefulWidget {
  final Turf turf;

  const TurfDetailsScreen({required this.turf});

  @override
  _TurfDetailsScreenState createState() => _TurfDetailsScreenState();
}

class _TurfDetailsScreenState extends State<TurfDetailsScreen> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentImageIndex = 0;
  DateTime _selectedDate = DateTime.now();
  dynamic _selectedSlot;
  String? _selectedGround;

  @override
  void initState() {
    super.initState();
    if (widget.turf.grounds.isNotEmpty) {
      _selectedGround = widget.turf.grounds[0];
    }
    _fetchSlots();
    _fetchReviews();
  }

  void _fetchSlots() {
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false)
            .fetchSlots(widget.turf.id, _selectedDate, groundName: _selectedGround));
  }

  void _fetchReviews() {
    Future.microtask(() =>
        Provider.of<ReviewProvider>(context, listen: false)
            .fetchTurfReviews(widget.turf.id));
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.turf.operationalStatus != 'normal') 
                    _buildGroundStatusNotice(),
                  _buildTurfInfo(),
                  _buildRatingSection(),
                   const SizedBox(height: 32),
                   if (widget.turf.grounds.isNotEmpty) ...[
                     _buildGroundPicker(),
                     const SizedBox(height: 24),
                   ],
                   _buildDatePicker(),
                   const SizedBox(height: 24),
                  _buildSectionHeader('Available Slots'),
                  const SizedBox(height: 16),
                  if (bookingProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (bookingProvider.availableSlots.isEmpty)
                    _buildEmptySlots()
                  else
                    Builder(builder: (context) {
                      final now = DateTime.now();
                      final isToday = DateFormat('yyyyMMdd').format(_selectedDate) == DateFormat('yyyyMMdd').format(now);
                      final filteredSlots = isToday 
                        ? bookingProvider.availableSlots.where((slot) {
                            final startTimeStr = slot['startTime'] as String;
                            final parts = startTimeStr.split(':');
                            final slotTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
                            final graceTime = slotTime.add(const Duration(minutes: 15));
                            return graceTime.isAfter(now);
                          }).toList()
                        : bookingProvider.availableSlots;

                      if (filteredSlots.isEmpty) return _buildEmptySlots();
                      return _buildSlotGrid(filteredSlots);
                    }),
                ],
              ),
            ),
          ),
          _buildReviewsHeader(reviewProvider),
          _buildReviewsList(reviewProvider),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(bookingProvider),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.green[800],
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.45),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.turf.images.isNotEmpty)
              CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                  height: 300,
                  viewportFraction: 1.0,
                  autoPlay: widget.turf.images.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() => _currentImageIndex = index);
                  },
                ),
                items: widget.turf.images.map((img) => 
                  Image.network(
                    ApiConstants.getFullUrl(img),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.stadium_outlined, size: 80, color: Colors.grey[400]),
                    ),
                  )
                ).toList(),
              )
            else
              Container(
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
              ),
            // Gradient Overlay with smooth bottom transition
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // Left Side Arrow (Previous Photo)
            if (widget.turf.images.length > 1)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _carouselController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Right Side Arrow (Next Photo)
            if (widget.turf.images.length > 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _carouselController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Photo Indicator Badge (e.g. 1/3)
            if (widget.turf.images.length > 1)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${widget.turf.images.length}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Floating Turf Type Badge on bottom-right of image
            Positioned(
              bottom: 16,
              right: 16,
              child: TurfTypeBadge(type: widget.turf.turfType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurfInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.turf.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.green[900]?.withOpacity(0.3) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.green[700]!.withOpacity(0.4) : const Color(0xFFA5D6A7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Approved',
                    style: GoogleFonts.outfit(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.green[800], size: 16),
            const SizedBox(width: 4),
            Text(
              '${widget.turf.area}, ${widget.turf.city}', 
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Amenities', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.turf.amenities.map((a) => _buildAmenityChip(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildGroundStatusNotice() {
    final status = widget.turf.operationalStatus;
    Color color = Colors.grey;
    IconData icon = Icons.info_outline_rounded;
    String label = status.toUpperCase();

    switch (status) {
      case 'wet':
        color = Colors.blue;
        icon = Icons.water_drop_rounded;
        label = 'WET / SLIPPERY';
        break;
      case 'maintenance':
        color = Colors.orange;
        icon = Icons.build_rounded;
        label = 'UNDER MAINTENANCE';
        break;
      case 'heavy-rain':
        color = Colors.indigo;
        icon = Icons.cloudy_snowing;
        label = 'HEAVILY RAINED';
        break;
      case 'power-issue':
        color = Colors.red;
        icon = Icons.flash_off_rounded;
        label = 'POWER ISSUE';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Please consider this before booking.',
                  style: GoogleFonts.outfit(
                    color: color.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber[900]?.withOpacity(0.15) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.amber[700]!.withOpacity(0.3) : const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Text(
            widget.turf.avgRating.toStringAsFixed(1),
            style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.amber[900]),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.turf.avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber[800],
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.turf.numReviews} ${widget.turf.numReviews == 1 ? 'Review' : 'Reviews'}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber[900]?.withOpacity(0.75)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader(ReviewProvider reviewProvider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Player Reviews', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            if (reviewProvider.turfReviews.isNotEmpty)
              TextButton(
                onPressed: () => _showAllReviewsBottomSheet(reviewProvider),
                child: Text(
                  'See All (${reviewProvider.turfReviews.length})', 
                  style: GoogleFonts.outfit(color: Colors.green[800], fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllReviewsBottomSheet(ReviewProvider reviewProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Reviews (${reviewProvider.turfReviews.length})', 
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: reviewProvider.turfReviews.length,
                  itemBuilder: (context, index) => _buildReviewCard(reviewProvider.turfReviews[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(ReviewProvider provider) {
    if (provider.isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    if (provider.turfReviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50]?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.rate_review_outlined, color: Colors.green[800], size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No reviews yet', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[900]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Be the first to play and leave a review after your match!', 
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.green[800]?.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == (provider.turfReviews.length > 3 ? 3 : provider.turfReviews.length)) {
            if (provider.turfReviews.length <= 2) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  'Played here recently? Leave a detailed review after your match!',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          return _buildReviewCard(provider.turfReviews[index]);
        },
        childCount: (provider.turfReviews.length > 3 ? 3 : provider.turfReviews.length) + (provider.turfReviews.length <= 2 ? 1 : 0),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                backgroundImage: review.userProfileImage != null ? NetworkImage(review.userProfileImage!) : null,
                child: review.userProfileImage == null 
                  ? Text(review.userName.isNotEmpty ? review.userName[0] : 'U', style: TextStyle(color: Colors.green[800], fontSize: 12)) 
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 12,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(DateFormat('dd MMM').format(review.createdAt), style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('change') || lower.contains('room')) return Icons.checkroom_rounded;
    if (lower.contains('wash') || lower.contains('toilet')) return Icons.wc_rounded;
    if (lower.contains('water') || lower.contains('drink')) return Icons.water_drop_rounded;
    if (lower.contains('light') || lower.contains('flood')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('first aid') || lower.contains('medical')) return Icons.medical_services_outlined;
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('canteen') || lower.contains('cafe')) return Icons.restaurant_rounded;
    if (lower.contains('shower')) return Icons.shower_rounded;
    if (lower.contains('locker')) return Icons.lock_outline_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildAmenityChip(String label) {
    final icon = _getAmenityIcon(label);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.green[800]),
          const SizedBox(width: 6),
          Text(
            label, 
            style: GoogleFonts.outfit(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Date', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text('14 Days Available', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white,
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.85, 0.94, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = DateFormat('yyyyMMdd').format(date) == 
                                  DateFormat('yyyyMMdd').format(_selectedDate);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null;
                    });
                    _fetchSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    margin: const EdgeInsets.only(right: 12, bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[800] : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                        else
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                      border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white70 : Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('d').format(date),
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSlotGrid(List<dynamic> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isBooked = slot['isBooked'] == true;
        final isBlocked = slot['isBlocked'] == true;
        final slotId = slot['_id'] ?? slot['id'];
        final selectedSlotId = _selectedSlot != null ? (_selectedSlot['_id'] ?? _selectedSlot['id']) : null;
        final isSelected = _selectedSlot == slot || (slotId != null && slotId == selectedSlotId);
        final isUnavailable = isBooked || isBlocked;

        return GestureDetector(
          onTap: isUnavailable 
            ? null 
            : () => setState(() {
                if (isSelected) {
                  _selectedSlot = null;
                } else {
                  _selectedSlot = slot;
                }
              }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.green[800] 
                : isUnavailable 
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100]) 
                    : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: Colors.green.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))
                else if (!isUnavailable)
                  BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 1))
              ],
              border: Border.all(
                color: isSelected 
                  ? Colors.green[800]! 
                  : isUnavailable 
                      ? Colors.grey[300]! 
                      : Colors.green[600]!,
                width: isSelected ? 2 : 1.2,
              ),
            ),
            child: Center(
              child: isBooked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot['startTime'],
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey[400],
                          ),
                        ),
                        Text(
                          'BOOKED',
                          style: GoogleFonts.outfit(
                            color: Colors.red[400],
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : isBlocked
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot['startTime'],
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              'BLOCKED',
                              style: GoogleFonts.outfit(
                                color: Colors.orange[400],
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          slot['startTime'],
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.green[800],
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySlots() {
    final nextDate = _selectedDate.add(const Duration(days: 1));
    final nextDayName = DateFormat('EEEE').format(nextDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, color: Colors.grey[400], size: 44),
          const SizedBox(height: 10),
          Text(
            'No slots available for ${DateFormat('EEE, d MMM').format(_selectedDate)}',
            style: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'All slots might be booked or closed for this day.',
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = nextDate;
                _selectedSlot = null;
              });
              _fetchSlots();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text('Try $nextDayName (${DateFormat('d MMM').format(nextDate)})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '---';
    final numVal = num.tryParse(price.toString()) ?? 0;
    if (numVal == numVal.roundToDouble()) {
      return '₹${NumberFormat('#,##,###').format(numVal.toInt())}';
    }
    return '₹${NumberFormat('#,##,###.##').format(numVal)}';
  }

  Widget _buildBottomBar(BookingProvider provider) {
    final bool isEnabled = _selectedSlot != null && !provider.isLoading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), 
            blurRadius: 10, 
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price', 
                    style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(_selectedSlot != null ? _selectedSlot['price'] : null),
                    style: GoogleFonts.outfit(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      color: _selectedSlot != null ? Colors.green[800] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isEnabled ? () => _handleBooking(provider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled ? Colors.green[800] : Colors.grey[300],
                  foregroundColor: isEnabled ? Colors.white : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
                  elevation: isEnabled ? 2 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: provider.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BOOK NOW', 
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (isEnabled) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBooking(BookingProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryScreen(
          turf: widget.turf,
          slot: _selectedSlot,
          date: _selectedDate,
        ),
      ),
    );
  }

  IconData _getGroundIcon(String groundName) {
    final lower = groundName.toLowerCase();
    if (lower.contains('cricket')) return Icons.sports_cricket_rounded;
    if (lower.contains('football') || lower.contains('soccer')) return Icons.sports_soccer_rounded;
    if (lower.contains('tennis')) return Icons.sports_tennis_rounded;
    if (lower.contains('badminton')) return Icons.sports_tennis_rounded;
    if (lower.contains('basketball')) return Icons.sports_basketball_rounded;
    return Icons.stadium_outlined;
  }

  Widget _buildGroundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Ground', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: widget.turf.grounds.map((ground) {
            final isSelected = _selectedGround == ground;
            final icon = _getGroundIcon(ground);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGround = ground;
                  _selectedSlot = null;
                });
                _fetchSlots();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[800] : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                  border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ground,
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
