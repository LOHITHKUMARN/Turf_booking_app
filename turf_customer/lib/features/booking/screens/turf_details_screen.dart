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
          _buildReviewsHeader(),
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
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.turf.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  viewportFraction: 1.0,
                  autoPlay: true,
                ),
                items: widget.turf.images.map((img) => 
                  Image.network(ApiConstants.getFullUrl(img), fit: BoxFit.cover, width: double.infinity)
                ).toList(),
              )
            else
              Container(
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
              ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurfInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.turf.name.toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 8),
                  TurfTypeBadge(type: widget.turf.turfType),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.green[900]?.withOpacity(0.3) : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Approved', style: GoogleFonts.outfit(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.green[800], size: 18),
            const SizedBox(width: 4),
            Text('${widget.turf.area}, ${widget.turf.city}', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Amenities', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
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
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Please consider this before booking.',
                  style: GoogleFonts.outfit(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber[900]?.withOpacity(0.2) : Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.amber[700]!.withOpacity(0.3) : Colors.amber[100]!),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.turf.avgRating.toStringAsFixed(1),
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                  ),
                  const SizedBox(width: 8),
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
                      Text(
                        '${widget.turf.numReviews} Reviews',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber[900]?.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.reviews_outlined, color: Colors.amber[800], size: 32),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Player Reviews', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: Text('See All', style: GoogleFonts.outfit(color: Colors.green[800], fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(ReviewProvider provider) {
    if (provider.isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    if (provider.turfReviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('No reviews yet. Be the first to play and rate!',
                style: GoogleFonts.outfit(color: Colors.grey[500]), textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildReviewCard(provider.turfReviews[index]),
        childCount: provider.turfReviews.length > 3 ? 3 : provider.turfReviews.length,
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
                child: review.userProfileImage == null ? Text(review.userName[0], style: TextStyle(color: Colors.green[800], fontSize: 12)) : null,
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

  Widget _buildAmenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[800]),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Date', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
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
                  duration: const Duration(milliseconds: 300),
                  width: 75,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[800] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d').format(date),
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.black,
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
        childAspectRatio: 2.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isBooked = slot['isBooked'] ?? false;
        final isBlocked = slot['isBlocked'] ?? false;
        final isSelected = _selectedSlot == slot;
        final isUnavailable = isBooked || isBlocked;

        return GestureDetector(
          onTap: isUnavailable ? null : () => setState(() => _selectedSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.green[800] 
                : isUnavailable 
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[50]) 
                    : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                else if (!isUnavailable)
                  BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 1))
              ],
              border: Border.all(
                color: isSelected 
                  ? Colors.green[800]! 
                  : isUnavailable ? Theme.of(context).dividerColor : Colors.green[600]!,
                width: isSelected ? 2 : 1.2,
              ),
            ),
            child: Center(
              child: Text(
                slot['startTime'],
                style: GoogleFonts.outfit(
                  color: isSelected 
                    ? Colors.white 
                    : isUnavailable ? Colors.grey[400] : Colors.green[800],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, color: Colors.grey[400], size: 48),
          const SizedBox(height: 8),
          Text('No slots available for this date.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Price', style: GoogleFonts.outfit(color: Colors.grey[600])),
                Text(
                  _selectedSlot != null ? '₹${_selectedSlot['price'] ?? 0}' : '---',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedSlot == null || provider.isLoading 
                ? null 
                : () => _handleBooking(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('BOOK NOW', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
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

  Widget _buildGroundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Ground', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.turf.grounds.map((ground) {
            final isSelected = _selectedGround == ground;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGround = ground;
                  _selectedSlot = null;
                });
                _fetchSlots();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                  border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[200]!),
                ),
                child: Text(
                  ground,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
