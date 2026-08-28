import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/turf_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/turf_model.dart';
import '../../../core/constants/locations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/socket_service.dart';
import '../../booking/screens/turf_details_screen.dart';
import '../widgets/turf_type_badge.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<TurfProvider>(context, listen: false).fetchTurfs());
    
    // Listen for real-time announcements
    SocketService().on('newAnnouncement', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📣 ${data['title']}: ${data['content']}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to announcements if needed
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService().off('newAnnouncement');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => turfProvider.fetchTurfs(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildUniqueHeader(auth, turfProvider)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildFilterChips(turfProvider)),
            SliverToBoxAdapter(child: _buildSectionHeader('Explore Grounds')),
            if (turfProvider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (turfProvider.filteredTurfs.isEmpty)
              _buildEmptyState(turfProvider.selectedLocation, turfProvider.searchQuery)
            else
              _buildTurfGrid(turfProvider.filteredTurfs),
          ],
        ),
      ),
    );
  }

  Widget _buildUniqueHeader(AuthProvider auth, TurfProvider turfProvider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Gradient Container
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[900]!,
                Colors.green[700]!,
                const Color(0xFF1B5E20),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              // Decorative Circular Spotlight
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Location & Logout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _showLocationPicker(context, turfProvider),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.green[200], size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CURRENT LOCATION',
                                      style: GoogleFonts.outfit(
                                        color: Colors.green[200],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      turfProvider.selectedLocation,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => auth.logout(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Greeting
                      Text(
                        'Hi, ${auth.user?['name']?.split(' ')[0] ?? 'Player'}! 👋',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Book your favorite turf in seconds.',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlapping Search Bar
        Positioned(
          bottom: -28,
          left: 24,
          right: 24,
          child: _buildFloatingSearchBar(),
        ),
      ],
    );
  }

  void _showLocationPicker(BuildContext context, TurfProvider provider) {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<String> filteredLocations = Locations.indianCities
              .where((loc) => loc.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Location',
                      style: GoogleFonts.outfit(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredLocations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        filteredLocations[index],
                        style: GoogleFonts.outfit(
                          color: provider.selectedLocation == filteredLocations[index] ? Colors.green[800] : Colors.black87,
                          fontWeight: provider.selectedLocation == filteredLocations[index] ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: provider.selectedLocation == filteredLocations[index] ? Icon(Icons.check_circle, color: Colors.green[800]) : null,
                      onTap: () {
                        provider.setLocation(filteredLocations[index]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => Provider.of<TurfProvider>(context, listen: false).setSearchQuery(value),
        style: GoogleFonts.outfit(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search grounds, sports or area...',
          hintStyle: GoogleFonts.outfit(color: Theme.of(context).hintColor, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.green, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune_rounded, color: Colors.green[800], size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }


  Widget _buildFilterChips(TurfProvider turfProvider) {
    final turfTypes = ['All', 'Indoor', 'Outdoor', 'Both'];
    final sports = ['All', ...turfProvider.availableSports];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Turf type chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: turfTypes.map((type) {
              final isSelected = turfProvider.selectedTurfType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => turfProvider.setTurfType(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[800] : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.green[800]! : Theme.of(context).dividerColor,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (type == 'Indoor') Icon(Icons.roofing_rounded, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
                        if (type == 'Outdoor') Icon(Icons.wb_sunny_rounded, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
                        if (type == 'Both') Icon(Icons.compare_arrows_rounded, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
                        if (type == 'All') Icon(Icons.grid_view_rounded, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          type,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Sport chips (only if sports are available)
        if (turfProvider.availableSports.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              children: sports.map((sport) {
                final isSelected = turfProvider.selectedSport == sport;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => turfProvider.setSport(sport),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.green[600]! : Theme.of(context).dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        sport,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.green[800] : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: Text('View All', style: TextStyle(color: Colors.green[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildTurfGrid(List<Turf> turfs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildTurfCard(turfs[index]),
          childCount: turfs.length,
        ),
      ),
    );
  }

  Widget _buildTurfCard(Turf turf) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TurfDetailsScreen(turf: turf),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: turf.firstImageUrl != null && turf.firstImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(ApiConstants.getFullUrl(turf.firstImageUrl)), 
                        fit: BoxFit.cover
                      )
                    : null,
                ),
                child: turf.firstImageUrl == null || turf.firstImageUrl!.isEmpty
                  ? Center(child: Icon(Icons.image, color: Colors.grey[400]))
                  : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turf.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          turf.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TurfTypeBadge(type: turf.turfType),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: turf.sports.take(2).map((s) => _buildSportTag(s)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportTag(String sport) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sport,
        style: GoogleFonts.outfit(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String location, String query) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query.isEmpty ? Icons.location_off_rounded : Icons.search_off_rounded, 
              size: 80, 
              color: Colors.grey[200]
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty 
                ? 'No turfs found in $location'
                : 'No results for "$query"',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                ? 'Try selecting another location\nor check back later!'
                : 'Try searching for something else!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
