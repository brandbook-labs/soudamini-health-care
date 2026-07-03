import 'package:flutter/material.dart';
import '../../../models/doctor_model.dart';
import '../../../services/api_service.dart';

class DoctorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  final List<Doctor> _doctorsList = [];
  List<Doctor> get doctorsList => _doctorsList;

  bool _isListFirstLoading = true;
  bool get isListFirstLoading => _isListFirstLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  int _currentPage = 1;
  final int _limit = 10;

  final Set<String> _specialties = {};
  List<String> get specialties => _specialties.toList();

  final Set<String> _clinics = {};
  List<String> get clinics => _clinics.toList();

  final Set<String> _cities = {};
  List<String> get cities => _cities.toList();

  double? _currentLat;
  double? _currentLng;
  String? _fallbackLocationText; 
  String? _userTypedSearch;      

  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  String? get searchQuery => _userTypedSearch ?? _fallbackLocationText;

  Doctor? _selectedDoctorProfile;
  Doctor? get selectedDoctorProfile => _selectedDoctorProfile;

  bool _isProfileLoading = false;
  bool get isProfileLoading => _isProfileLoading;

  // 🚀 THE FIX: Smart Update Logic
  void updateLocationFromUserProvider({
    required double lat, 
    required double lng, 
    required String fallbackLocation, 
  }) {
    if (_currentLat == lat && 
        _currentLng == lng && 
        _fallbackLocationText == fallbackLocation) {
      
      // 🚀 ଯଦି ସବୁକିଛି ସମାନ ଅଛି କିନ୍ତୁ ଡାକ୍ତର ଲିଷ୍ଟ୍ ଖାଲି ଅଛି, ତେବେ ବାଧ୍ୟତାମୂଳକ API କଲ୍ କରନ୍ତୁ
      if (_doctorsList.isEmpty && !_isListFirstLoading) {
        fetchNearestDoctors(isRefresh: true);
      }
      return; 
    }

    _currentLat = lat;
    _currentLng = lng;
    _fallbackLocationText = fallbackLocation.isEmpty ? null : fallbackLocation;
    
    fetchNearestDoctors(isRefresh: true);
  }

  void applySearch(String query) {
    final cleanQuery = query.trim();
    if (_userTypedSearch == cleanQuery) return; 
    
    _userTypedSearch = cleanQuery.isEmpty ? null : cleanQuery;
    fetchNearestDoctors(isRefresh: true);
  }

  void clearSearch() {
    if (_userTypedSearch == null) return;
    _userTypedSearch = null;
    fetchNearestDoctors(isRefresh: true);
  }

  Future<void> fetchNearestDoctors({bool isRefresh = false}) async {
    bool hasGps = (_currentLat != null && _currentLat != 0.0) && (_currentLng != null && _currentLng != 0.0);
    
    String? finalSearchQuery = _userTypedSearch;
    if (!hasGps && (_userTypedSearch == null || _userTypedSearch!.isEmpty)) {
      finalSearchQuery = _fallbackLocationText;
    }

    if (!hasGps && (finalSearchQuery == null || finalSearchQuery.isEmpty)) {
      debugPrint("Provider Warning: No GPS and No Search Text. Skipping fetch.");
      _isListFirstLoading = false;
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _isListFirstLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
      _doctorsList.clear();
      Future.microtask(() => notifyListeners()); 
    } else {
      if (!_hasMoreData || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners(); 
    }

    try {
      final List<Doctor> newDoctors = await _apiService.getNearestDoctorsList(
        page: _currentPage, 
        limit: _limit,
        lat: hasGps ? _currentLat : null, 
        lng: hasGps ? _currentLng : null, 
        searchQuery: finalSearchQuery, 
      );

      if (newDoctors.length < _limit) {
        _hasMoreData = false;
      }
      
      _doctorsList.addAll(newDoctors);
      _currentPage++;

    } catch (e) {
      debugPrint("Provider Error fetching doctors list: $e");
    } finally {
      _isListFirstLoading = false;
      _isLoadingMore = false;
      notifyListeners(); 
    }
  }

  Future<void> fetchSingleDoctorProfile(String slug) async {
    _isProfileLoading = true;
    _selectedDoctorProfile = null; 
    Future.microtask(() => notifyListeners());

    try {
      final Doctor profileData = await _apiService.getDoctorProfileDetails(
        slug: slug,
        lat: (_currentLat != null && _currentLat != 0.0) ? _currentLat : null,
        lng: (_currentLng != null && _currentLng != 0.0) ? _currentLng : null,
      );
      _selectedDoctorProfile = profileData;
    } catch (e) {
      debugPrint("Provider Error fetching doctor profile: $e");
    } finally {
      _isProfileLoading = false;
      notifyListeners(); 
    }
  }

  // =========================================================
  // 🚀 DEPARTMENTS CACHE STATE
  // =========================================================
  List<dynamic> _departments = [];
  List<dynamic> get departments => _departments;

  bool _isLoadingDepartments = false;
  bool get isLoadingDepartments => _isLoadingDepartments;

  Future<void> fetchDepartmentsOnce() async {
    if (_departments.isNotEmpty) return;

    _isLoadingDepartments = true;
    notifyListeners();

    try {
      final response = await _apiService.getRogDepartments();
      if (response.statusCode == 200 && response.data['data'] != null) {
        _departments = response.data['data'];
      }
    } catch (e) {
      debugPrint("Provider Error fetching departments: $e");
    } finally {
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  // =========================================================
  // 🚀 [NEW SENIOR LOGIC]: LOGOUT CLEAR DATA (ସବା ତଳେ)
  // =========================================================
  void clearData() {
    // ୧. ଡାକ୍ତର ଲିଷ୍ଟ୍ ଏବଂ ଫିଲ୍ଟର୍ ଡାଟା ସଫା କରନ୍ତୁ
    _doctorsList.clear();
    _specialties.clear();
    _clinics.clear();
    _cities.clear();

    // ୨. ଡିପାର୍ଟମେଣ୍ଟ୍ କ୍ୟାସ୍ ସଫା କରନ୍ତୁ
    _departments.clear();

    // ୩. ପେଜିନେସନ୍ (Pagination) ରିସେଟ୍ କରନ୍ତୁ
    _currentPage = 1;
    _hasMoreData = true;
    _isListFirstLoading = true;
    _isLoadingMore = false;

    // ୪. ଲୋକେସନ୍ ଏବଂ ସର୍ଚ୍ଚ ଡାଟା ରିସେଟ୍ କରନ୍ତୁ
    _currentLat = null;
    _currentLng = null;
    _fallbackLocationText = null;
    _userTypedSearch = null;

    // ୫. ସିଙ୍ଗଲ୍ ଡାକ୍ତର ପ୍ରୋଫାଇଲ୍ ରିସେଟ୍
    _selectedDoctorProfile = null;
    _isProfileLoading = false;
    _isLoadingDepartments = false;

    // ୬. UI କୁ ରିଫ୍ରେସ୍ କରିବା ପାଇଁ ସିଗନାଲ୍
    notifyListeners();
  }
}