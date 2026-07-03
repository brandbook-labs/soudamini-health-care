import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import '../../../models/clinic_model.dart';
import '../../../models/doctor_model.dart'; 
import '../../../services/api_service.dart';

class ClinicProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Clinic> _clinics = [];
  List<Clinic> get clinics => _clinics;

  // 🚀 SINGLE CLINIC PROFILE STATE
  Clinic? _selectedClinic;
  Clinic? get selectedClinic => _selectedClinic;

  // 🚀 SERVICES & DOCTORS STATE
  List<dynamic> _clinicServices = [];
  List<dynamic> get clinicServices => _clinicServices;

  List<Doctor> _clinicDoctors = [];
  List<Doctor> get clinicDoctors => _clinicDoctors;

  bool _isFirstLoading = true;
  bool get isFirstLoading => _isFirstLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isProfileLoading = true; 
  bool get isProfileLoading => _isProfileLoading;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  int _currentPage = 1;
  final int _limit = 10;

  // ==========================================
  // 🚀 GLOBAL SEARCH & LOCATION STATE (SMART)
  // ==========================================
  double? _lat;
  double? _lng;
  String? _fallbackLocationText; // GPS ନଥିଲେ ଏହି ଠିକଣା (City/District) searchQuery କୁ ଯିବ
  String? _userTypedSearch;      // ୟୁଜର୍ ନିଜେ ସର୍ଚ୍ଚ କଲେ ଏଥିରେ ରହିବ

  double? get currentLat => _lat;
  double? get currentLng => _lng;
  String? get searchQuery => _userTypedSearch ?? _fallbackLocationText;

  // ==========================================
  // 🚀 HELPER METHOD: Update from UserProvider
  // ==========================================
  void updateLocationFromUserProvider({
    required double lat, 
    required double lng, 
    required String fallbackLocation, 
  }) {
    // Optimization: ଯଦି ଡାଟା ସମାନ ଅଛି, ତେବେ ଅଯଥା କଲ୍ କରନ୍ତୁ ନାହିଁ (Fast Performance)
    if (_lat == lat && 
        _lng == lng && 
        _fallbackLocationText == fallbackLocation) {
      
      // ଯଦି ସବୁକିଛି ସମାନ ଅଛି କିନ୍ତୁ କ୍ଲିନିକ୍ ଲିଷ୍ଟ୍ ଖାଲି ଅଛି, ତେବେ ବାଧ୍ୟତାମୂଳକ API କଲ୍ କରନ୍ତୁ
      if (_clinics.isEmpty && !_isFirstLoading) {
        fetchClinics(isRefresh: true);
      }
      return; 
    }

    _lat = lat;
    _lng = lng;
    _fallbackLocationText = fallbackLocation.isEmpty ? null : fallbackLocation;
    
    fetchClinics(isRefresh: true);
  }

  // ==========================================
  // 🚀 API CALL: Fetch Clinics (With Safe Fallback)
  // ==========================================
  Future<void> fetchClinics({
    bool isRefresh = false, 
    String? searchQuery, // ଯଦି ମାନୁଆଲ୍ ସର୍ଚ୍ଚ ଆସେ
  }) async {
    if (searchQuery != null) {
      final cleanQuery = searchQuery.trim();
      _userTypedSearch = cleanQuery.isEmpty ? null : cleanQuery;
    }

    // 🛡️ SECURITY: GPS ଯାଞ୍ଚ କରିବା (0.0 ମାନେ GPS ନାହିଁ)
    bool hasGps = (_lat != null && _lat != 0.0) && (_lng != null && _lng != 0.0);
    
    // 🚀 DYNAMIC SEARCH QUERY DECISION 🚀
    String? finalSearchQuery = _userTypedSearch;
    if (!hasGps && (_userTypedSearch == null || _userTypedSearch!.isEmpty)) {
      finalSearchQuery = _fallbackLocationText;
    }

    // ଯଦି ନା GPS ଅଛି ନା କିଛି ଠିକଣା ଅଛି, ତେବେ ଅଯଥା ବ୍ୟାକ୍-ଏଣ୍ଡ୍ କୁ କଲ୍ ନକରିବା ଭଲ
    if (!hasGps && (finalSearchQuery == null || finalSearchQuery.isEmpty)) {
      debugPrint("ClinicProvider Warning: No GPS and No Search Text. Skipping fetch.");
      _isFirstLoading = false;
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _isFirstLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
      _clinics.clear();
      Future.microtask(() => notifyListeners()); 
    } else {
      if (!_hasMoreData || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners(); 
    }

    try {
      final List<Clinic> newClinics = await _apiService.getUserClinics(
        page: _currentPage,
        limit: _limit,
        lat: hasGps ? _lat : null, 
        lng: hasGps ? _lng : null, 
        search: finalSearchQuery, // 🚀 ବ୍ୟାକ୍-ଏଣ୍ଡ୍ କୁ ପରଫେକ୍ଟ୍ ସର୍ଚ୍ଚ କ୍ୱେରୀ ଯିବ
      );

      if (newClinics.length < _limit) {
        _hasMoreData = false;
      }

      _clinics.addAll(newClinics);
      _currentPage++;
      
    } catch (e) {
      debugPrint("Clinic API Error: $e");
    } finally {
      _isFirstLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void searchClinics(String query) {
    if (_userTypedSearch == query.trim()) return;
    fetchClinics(isRefresh: true, searchQuery: query);
  }

  // 🚀 [SUPER SENIOR LOGIC]: PARALLEL API CALLS 🚀
  Future<void> fetchSingleClinicProfile(String slug) async {
    _isProfileLoading = true;
    _clinicServices = []; // Reset old data
    _clinicDoctors = [];  // Reset old data
    Future.microtask(() => notifyListeners()); 
    
    try {
      // ୧. ୩ଟି ଯାକ API ଏକାସାଙ୍ଗରେ କଲ୍ ହେବ
      final profileFuture = _apiService.getClinicProfileDetails(slug: slug);
      final servicesFuture = _apiService.getClinicServicesForUser(slug: slug);
      final doctorsFuture = _apiService.getClinicDoctorsForUser(slug: slug);

      // ୨. ସବୁ ରେସପନ୍ସ (Response) କୁ ଏକାସାଙ୍ଗରେ ଅପେକ୍ଷା କରିବା
      final results = await Future.wait([profileFuture, servicesFuture, doctorsFuture]);

      // ୩. ପ୍ରୋଫାଇଲ୍ ଡାଟା ସେଭ୍ 
      _selectedClinic = results[0] as Clinic;

      // ୪. ସର୍ଭିସ୍ (Services) ଡାଟା ସୁରକ୍ଷିତ ଭାବେ ପାର୍ସ (Parse) କରିବା
      final servicesRes = results[1] as Response;
      if (servicesRes.statusCode == 200 && servicesRes.data['data'] != null) {
        _clinicServices = servicesRes.data['data'];
      }

      // ୫. ଡାକ୍ତର (Doctors) ଡାଟା ସୁରକ୍ଷିତ ଭାବେ ପାର୍ସ କରିବା
      final doctorsRes = results[2] as Response;
      if (doctorsRes.statusCode == 200 && doctorsRes.data['data'] != null) {
        final dynamic docsData = doctorsRes.data['data'];
        List<dynamic> rawDoctors = [];
        
        if (docsData is List) {
          rawDoctors = docsData;
        } else if (docsData is Map && docsData['doctors'] != null) {
          rawDoctors = docsData['doctors'];
        }

        _clinicDoctors = rawDoctors.map((json) => Doctor.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching clinic full details: $e");
    } finally {
      _isProfileLoading = false;
      notifyListeners(); 
    }
  }

  // =========================================================
  // 🚀 [NEW SENIOR LOGIC]: LOGOUT CLEAR DATA (ସବା ତଳେ)
  // =========================================================
  void clearData() {
    // ୧. କ୍ଲିନିକ୍ ଲିଷ୍ଟ୍ ଏବଂ ପେଜିନେସନ୍ କ୍ଲିୟର୍ (List & Pagination Reset)
    _clinics.clear();
    _currentPage = 1;
    _hasMoreData = true;
    _isFirstLoading = true;
    _isLoadingMore = false;

    // ୨. ସିଙ୍ଗଲ୍ କ୍ଲିନିକ୍ ପ୍ରୋଫାଇଲ୍ ଡାଟା କ୍ଲିୟର୍ (Profile Reset)
    _selectedClinic = null;
    _clinicServices.clear();
    _clinicDoctors.clear();
    _isProfileLoading = false;

    // ୩. ଲୋକେସନ୍ ଏବଂ ସର୍ଚ୍ଚ ଡାଟା କ୍ଲିୟର୍ (Search Reset)
    _lat = null;
    _lng = null;
    _fallbackLocationText = null;
    _userTypedSearch = null;

    // ୪. UI କୁ ସିଗନାଲ୍
    notifyListeners();
  }
}