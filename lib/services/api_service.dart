import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_new_app/core/constants/app_config.dart'; // 🚀 ଇମ୍ପୋର୍ଟ କରନ୍ତୁ
import 'package:my_new_app/models/staff_model.dart';
import '../models/clinic_model.dart';
import '../models/doctor_model.dart';

class ApiService {
  // final String _baseUrl = 'http://localhost:5000/api/v2/';
  final String _baseUrl = 'https://api.jivan.website/api/v2/';
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // =========================================================
    // 🚀 THE MAGIC: DIO INTERCEPTOR (For 100+ APIs)
    // ଏହା ସବୁ ଆଉଟଗୋଇଙ୍ଗ୍ ରିକ୍ୱେଷ୍ଟ୍ (outgoing request) ରେ ଆପେ ଆପେ ହେଡର୍ ଯୋଡିଦେବ!
    // =========================================================
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // ଡାଇନାମିକ୍ ହେଡର୍ ସେଟ୍ କରାଗଲା
        options.headers['x-tenant-slug'] = AppConfig.tenantSlug;
        return handler.next(options); // ରିକ୍ୱେଷ୍ଟ୍ କୁ ଆଗକୁ ବଢିବାକୁ ଦିଅନ୍ତୁ
      },
    ));
  }

  // --- INTERNAL HELPERS (Reduces Boilerplate) ---

  Future<Options> _getAuthOptions({String key = 'auth_token'}) async {
    final token = await _storage.read(key: key);
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<MultipartFile?> _getXFilePart(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return MultipartFile.fromBytes(bytes, filename: file.name);
  }

  Future<Response> _request(Future<Response> Function() call) async {
    try {
      return await call();
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // GROUP 1: AUTHENTICATION (PUBLIC)
  // ===========================================================================

  Future<Response> sendOtp(String mobileNumber) => _request(
    () => _dio.post('/users/send-otp', data: {'phone': mobileNumber}),
  );

  Future<Response> verifyOtp(String mobileNumber, String otp) => _request(
    () => _dio.post(
      '/users/verify-otp',
      data: {'phone': mobileNumber, 'otp': otp},
    ),
  );

  Future<Response> userGoogleLogin(String code) =>
      _request(() => _dio.post('/users/google', data: {'code': code}));

  Future<Response> adminLogin(String username, String password) => _request(
    () =>
        _dio.post('/auth', data: {'username': username, 'password': password}),
  );

  Future<String?> getToken({String key = 'auth_token'}) =>
      _storage.read(key: key);
  Future<void> removeToken({String key = 'auth_token'}) =>
      _storage.delete(key: key);

  // ===========================================================================
  // GROUP 2: USER FEATURES START
  // ===========================================================================

  Future<Response> getUserProfile() async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(() => _dio.get('/users', options: opts));
  }

  Future<Response> updateProfile(
    Map<String, dynamic> data, {
    bool isMultipart = false,
  }) async {
    final token = await getToken(key: 'auth_token');
    final payload = isMultipart ? FormData.fromMap(data) : data;

    return _request(
      () => _dio.put(
        '/users',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            if (!isMultipart) 'Content-Type': 'application/json',
          },
        ),
      ),
    );
  }

  Future<List<Clinic>> getUserClinics({
    int page = 1,
    int limit = 10,
    double? lat,
    double? lng,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      // 🚀 SENIOR DEV LOGIC: ସର୍ଚ୍ଚ ଥିଲେ ଲୋକେସନ୍ ଯିବନି, ନଚେତ୍ ଡିଫଲ୍ଟ ଲୋକେସନ୍ ଯିବ 🚀
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      } else {
        // Default Bhadrak location (ଯଦି lat/lng ନାହିଁ)
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }

      final response = await _dio.get(
        '/users/clinics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 &&
          response.data['data']['clinics'] != null) {
        return (response.data['data']['clinics'] as List)
            .map((json) => Clinic.fromJson(json))
            .toList();
      }
      throw Exception("Failed to load clinics");
    } catch (e) {
      rethrow;
    }
  }

  Future<Clinic> getClinicProfileDetails({required String slug}) async {
    try {
      final response = await _dio.get('/users/clinics/$slug');

      if (response.statusCode == 200 && response.data['data'] != null) {
        // ଧ୍ୟାନ ଦିଅନ୍ତୁ: ଆପଣଙ୍କର ବ୍ୟାକ୍-ଏଣ୍ଡ୍ 'data' ଭିତରେ ସିଧା ଡାକ୍ତରଙ୍କ ଅବଜେକ୍ଟ ପଠାଉଛି (ଗତ ଆଲୋଚନା ଅନୁଯାୟୀ)
        final Map<String, dynamic> clinicJson = response.data['data'];

        return Clinic.fromJson(clinicJson);
      }
      throw Exception(response.data['msg'] ?? "Failed to load doctor profile");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Doctor>> getNearestDoctorsList({
    int page = 1,
    int limit = 10,
    double? lat,
    double? lng,
    String? searchQuery, // [NEW] ସର୍ଚ୍ଚ ପାଇଁ ପାରାମିଟର
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      // 🚀 SENIOR DEV LOGIC: ସର୍ଚ୍ଚ ଥିଲେ ଲୋକେସନ୍ ଯିବନି, ନଚେତ୍ ଡିଫଲ୍ଟ ଲୋକେସନ୍ ଯିବ 🚀
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      } else {
        // Default Bhadrak location (ଯଦି lat/lng ନାହିଁ)
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }

      final response = await _dio.get(
        '/users/doctors',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data']['doctors'] != null) {
        final List doctorsJson = response.data['data']['doctors'];

        return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
      }
      throw Exception(response.data['msg'] ?? "Failed to load doctors");
    } catch (e) {
      rethrow;
    }
  }

  Future<Doctor> getDoctorProfileDetails({
    required String slug,
    double? lat,
    double? lng,
  }) async {
    try {
      // ପ୍ରୋଫାଇଲ୍ ପାଇଁ ମଧ୍ୟ ଆମେ ଲୋକେସନ୍ ପଠାଇବା ଯାହାଦ୍ୱାରା ବ୍ୟାକ୍-ଏଣ୍ଡ୍
      // କ୍ଲିନିକ୍ ଗୁଡିକର ଦୂରତା (Distance) ମାପି ପାରିବ।
      final Map<String, dynamic> queryParams = {
        // testing purpose only remove lat lng value
        'lat': lat,
        'lng': lng,
      };

      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }

      // when delete testing then it comment out
      final response = await _dio.get(
        '/users/doctors/$slug', // ଆପଣଙ୍କ ବ୍ୟାକ୍-ଏଣ୍ଡ୍ ରାଉଟ୍ ଅନୁଯାୟୀ ଏହାକୁ ବଦଳାଇ ପାରିବେ
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        // ଧ୍ୟାନ ଦିଅନ୍ତୁ: ଆପଣଙ୍କର ବ୍ୟାକ୍-ଏଣ୍ଡ୍ 'data' ଭିତରେ ସିଧା ଡାକ୍ତରଙ୍କ ଅବଜେକ୍ଟ ପଠାଉଛି (ଗତ ଆଲୋଚନା ଅନୁଯାୟୀ)
        final Map<String, dynamic> doctorJson = response.data['data'];

        return Doctor.fromJson(doctorJson);
      }
      throw Exception(response.data['msg'] ?? "Failed to load doctor profile");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getClinicServicesForUser({required String slug}) async {
    return _request(() => _dio.get('/users/clinics/$slug/services'));
  }

  Future<Response> getClinicDoctorsForUser({required String slug}) async {
    return _request(() => _dio.get('/users/clinics/$slug/doctors'));
  }

  Future<Response> getUserDoctorsAppointments({
    int page = 1,
    int limit = 10,
  }) async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(
      () => _dio.get(
        '/users/appointments/doctors',
        queryParameters: {'page': page, 'limit': limit},
        options: opts,
      ),
    );
  }

  // =========================================================================
  // 3. REVIEWS ROUTES
  // =========================================================================

  // Public Route (କେହି ବି ଦେଖିପାରିବେ)
  // Public Route (କେହି ବି ରିଭ୍ୟୁ ଦେଖିପାରିବେ)
  Future<Response?> getReviewsList({
    required String targetId,
    String? source, // 🚀 Optional କରାଗଲା
    int page = 1,
    int limit = 10,
  }) async {
    return _request(
      () => _dio.get(
        '/reviews/list/$targetId',
        queryParameters: {
          if (source != null) 'source': source, // 🚀 କେବଳ ଯଦି ଥାଏ, ତେବେ ଯିବ
          'page': page,
          'limit': limit,
        },
      ),
    );
  }

  // Protected Route (କେବଳ ଲଗ୍-ଇନ୍ ୟୁଜର୍ ପାଇଁ)
  Future<Response?> getUserReviews({
    String? source, // 🚀 Optional କରାଗଲା
    int page = 1,
    int limit = 10,
  }) async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(
      () => _dio.get(
        '/reviews/my-reviews',
        queryParameters: {
          if (source != null) 'source': source, // 🚀 କେବଳ ଯଦି ଥାଏ, ତେବେ ଯିବ
          'page': page,
          'limit': limit,
        },
        options: opts,
      ),
    );
  }

  Future<Response?> addReview(Map<String, dynamic> reviewData) async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(
      () => _dio.post('/reviews/add', data: reviewData, options: opts),
    );
  }

  Future<Response?> updateReview(
    String reviewId,
    Map<String, dynamic> updateData,
  ) async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(
      () => _dio.put(
        '/reviews/update/$reviewId',
        data: updateData,
        options: opts,
      ),
    );
  }

  Future<Response?> deleteReview(String reviewId) async {
    final opts = await _getAuthOptions(key: 'auth_token');
    return _request(
      () => _dio.delete('/reviews/delete/$reviewId', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୧. GET APPOINTMENT LIST (Upcoming / History)
  // ==========================================================
  /// [tokenKey] ରେ 'auth_token' (ରୋଗୀ ପାଇଁ) କିମ୍ବା 'admin_token' (କ୍ଲିନିକ୍ ପାଇଁ) ପଠାନ୍ତୁ।
  Future<Response> getAppointmentList({
    required String tokenKey,
    String type = 'upcoming', // 'upcoming' କିମ୍ବା 'history'
    int page = 1,
    int limit = 10,
    bool today = false, // 🚀 ନୂଆ ପାରାମିଟର୍ (Default: false)
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);

    // କ୍ୱେରି ପାରାମିଟର୍ସ ପ୍ରସ୍ତୁତ କରନ୍ତୁ
    Map<String, dynamic> queryParams = {
      'type': type,
      'page': page,
      'limit': limit,
    };

    // ଯଦି today true ଅଛି, ତେବେ ଏହାକୁ API କ୍ୱେରିରେ ଯୋଡ଼ନ୍ତୁ
    if (today) {
      queryParams['today'] = 'true';
    }

    return _request(
      () => _dio.get(
        '/appointments/list',
        queryParameters: queryParams,
        options: opts,
      ),
    );
  }

  Future<Response> getAppointmentDetails({
    required String tokenKey,
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.get('/appointments/$appointmentId', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୨. BOOK APPOINTMENT (Unified)
  // ==========================================================
  Future<Response> bookAppointment({
    required String tokenKey,
    required Map<String, dynamic> bookingData,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.post('/appointments/book', data: bookingData, options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୭. VERIFY ONLINE PAYMENT (User App - Razorpay)
  // ==========================================================
  Future<Response> verifyAppointmentPayment({
    required String tokenKey, // 'auth_token'
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.post(
        '/appointments/verify-payment',
        data: {
          "booking_id": bookingId,
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        },
        options: opts,
      ),
    );
  }

  // ==========================================================
  // 🚀 ୮. GENERATE ADMIN QR LINK (Admin App)
  // ==========================================================
  Future<Response> generateAdminPaymentQR({
    required String tokenKey, // 'admin_token'
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.get('/appointments/generate-qr/$appointmentId', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୯. VERIFY ADMIN QR PAYMENT (Admin App Polling)
  // ==========================================================
  Future<Response> verifyAdminPaymentQR({
    required String tokenKey, // 'admin_token'
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.get('/appointments/verify-qr/$appointmentId', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୩. MARK PATIENT REACHED (User Only: pending -> confirmed)
  // ==========================================================
  Future<Response> markPatientReached({
    required String tokenKey, // Both support admin or user
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.put('/appointments/$appointmentId/reached', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୪. START CONSULTATION (Clinic/Doctor Only: confirmed -> checked_in)
  // ==========================================================
  Future<Response> startConsultation({
    required String tokenKey, // ଏଠାରେ ସବୁବେଳେ 'admin_token' ଯିବ
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.put('/appointments/$appointmentId/start', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୫. COMPLETE CONSULTATION (Clinic/Doctor Only: checked_in -> completed)
  // ==========================================================
  Future<Response> completeConsultation({
    required String tokenKey, // ଏଠାରେ 'admin_token' ଯିବ
    required String appointmentId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.put('/appointments/$appointmentId/complete', options: opts),
    );
  }

  // ==========================================================
  // 🚀 ୬. CANCEL APPOINTMENT (User/Clinic/Doctor)
  // ==========================================================
  Future<Response> cancelAppointment({
    required String tokenKey, // 'auth_token' ବା 'admin_token'
    required String appointmentId,
    required String cancelReason,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.put(
        '/appointments/$appointmentId/cancel',
        data: {'cancel_reason': cancelReason},
        options: opts,
      ),
    );
  }
  // Appointment End

  Future<Response> getRogDepartments() =>
      _request(() => _dio.get('/rogs/list-departments'));

  Future<Response> getClinicLocations() =>
      _request(() => _dio.get('/users/location'));

  // ==========================================================
  // 🚀 [NEW SENIOR DEV LOGIC]: GLOBAL SEARCH (Doctors & Clinics)
  // ==========================================================
  Future<Map<String, dynamic>> getGlobalSearchWithDoctorClinic({
    int page = 1,
    int limit = 10,
    double? lat,
    double? lng,
    String? locationText, // ଉଦାହରଣ: "Bhadrak" ବା ୟୁଜର୍ ର କରେଣ୍ଟ ଲୋକେସନ୍
    required String
    searchValue, // ଯାହା ୟୁଜର୍ ସର୍ଚ୍ଚ ବାର୍ ରେ ଟାଇପ୍ କରୁଛି (ବାଧ୍ୟତାମୂଳକ)
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'searchValue': searchValue.trim(), // ସର୍ଚ୍ଚ ଭେଲ୍ୟୁ ନିହାତି ଦରକାର
      };

      // ୧. ଯଦି GPS ଲୋକେସନ୍ (lat, lng) ଅଛି
      if (lat != null && lat != 0.0 && lng != null && lng != 0.0) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }
      // ୨. ଯଦି GPS ନାହିଁ, କିନ୍ତୁ କୌଣସି ସିଟି ବା ଠିକଣା (Location Text) ଅଛି
      else if (locationText != null && locationText.trim().isNotEmpty) {
        queryParams['locationText'] = locationText.trim();
      }

      // ⚠️ ନିଜର API Route ନାମ ଏଠାରେ ଦିଅନ୍ତୁ (ଯେମିତିକି '/users/search')
      final response = await _dio.get(
        '/users/search', // ଆପଣଙ୍କ Node.js ର ରାଉଟ୍
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];

        // ଏହା ଉଭୟ 'pagination' ଏବଂ 'results' ରିଟର୍ଣ୍ଣ କରିବ
        return {
          'pagination': data['pagination'],
          'results': data['results'] as List<dynamic>,
        };
      }

      throw Exception(response.data['msg'] ?? "Failed to global search");
    } catch (e) {
      // debugPrint("API Service Error (Global Search): $e");
      rethrow;
    }
  }
  // ===========================================================================
  // GROUP 2: USER FEATURES EEND
  // ===========================================================================

  // ===========================================================================
  // GROUP 3: ADMIN FEATURES (STAFF & CLINIC) START
  // ===========================================================================

  Future<Response> requestClinicOtp(Map<String, dynamic> data) =>
      _request(() => _dio.post('/clinics/request-otp', data: data));

  Future<Response> verifyAndRegisterClinic(Map<String, dynamic> data) =>
      _request(() => _dio.post('/clinics/verify-otp', data: data));

  Future<Response> getAdminProfile() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/auth/profile', options: opts));
  }

  // ===========================================================================
  // 🚀 SLOT MANAGEMENT API (Admin & Clinic)
  // ===========================================================================

  /// ୧. GET SLOTS (ସମସ୍ତ ସ୍ଲଟ୍ ଆଣିବା ପାଇଁ)
  /// [tokenKey] ରେ 'admin_token' ବା ସମ୍ପୃକ୍ତ ଟୋକେନ୍ ଦେବେ।
  /// [clinicId] କେବଳ SuperAdmin ପାଇଁ ଆବଶ୍ୟକ (Optional)।
  Future<Response> getSlots({
    required String tokenKey,
    String? clinicId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);

    // ଯଦି SuperAdmin ନିର୍ଦ୍ଦିଷ୍ଟ କ୍ଲିନିକ୍ ର ସ୍ଲଟ୍ ଦେଖିବାକୁ ଚାହାଁନ୍ତି, ତେବେ Query Param ଯିବ
    Map<String, dynamic>? queryParams;
    if (clinicId != null && clinicId.isNotEmpty) {
      queryParams = {'clinic_id': clinicId};
    }

    return _request(
      () => _dio.get(
        '/slots', // ଆପଣଙ୍କର ରୁଟ୍ ନାମ (e.g., '/api/v2/slots') ଦେବେ
        queryParameters: queryParams,
        options: opts,
      ),
    );
  }

  /// ୨. ADD SLOT (ନୂଆ ସ୍ଲଟ୍ ତିଆରି କରିବା ପାଇଁ)
  Future<Response> addSlot({
    required String tokenKey,
    required Map<String, dynamic> slotData,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(() => _dio.post('/slots', data: slotData, options: opts));
  }

  /// ୩. UPDATE SLOT (ସ୍ଲଟ୍ କୁ ଏଡିଟ୍ ବା ଅପଡେଟ୍ କରିବା ପାଇଁ)
  Future<Response> updateSlot({
    required String tokenKey,
    required String slotId,
    required Map<String, dynamic> updateData,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(
      () => _dio.put('/slots/$slotId', data: updateData, options: opts),
    );
  }

  /// ୪. DELETE SLOT (ସ୍ଲଟ୍ ଡିଲିଟ୍ କରିବା ପାଇଁ)
  Future<Response> deleteSlot({
    required String tokenKey,
    required String slotId,
  }) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return _request(() => _dio.delete('/slots/$slotId', options: opts));
  }

  // ==========================================
  // 1. Get All Staffs (Returns List of Staff)
  // ==========================================
  Future<List<Staff>> getAdminStaffs() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final response = await _request(
      () => _dio.get('/admin/staffs', options: opts),
    );

    if (response.statusCode == 200 && response.data != null) {
      List<dynamic> rawList = [];

      // 🚀 ସବୁ ପ୍ରକାରର API Structure କୁ ସମ୍ଭାଳିବା ପାଇଁ ଲଜିକ୍ (Pagination or Direct Array)
      if (response.data['data'] is List) {
        rawList = response.data['data'];
      } else if (response.data['data'] is Map &&
          response.data['data']['staffs'] is List) {
        rawList = response.data['data']['staffs']; // ଯଦି Pagination ଥାଏ
      } else if (response.data is List) {
        rawList = response.data;
      }

      // JSON କୁ Staff ମଡେଲ୍ ରେ କନଭର୍ଟ କରନ୍ତୁ
      return rawList.map((json) => Staff.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load staffs");
    }
  }

  // ==========================================
  // 2. Get Single Staff Details (Returns Single Staff)
  // ==========================================
  Future<Staff> getAdminStaffDetails(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final response = await _request(
      () => _dio.get('/admin/staffs/$id', options: opts),
    );

    if (response.statusCode == 200 && response.data != null) {
      // 🚀 'data' କିମ୍ବା ସିଧା Response ରୁ ଡାଟା ବାହାର କରନ୍ତୁ
      final data = response.data['data'] ?? response.data;

      return Staff.fromJson(data); // JSON କୁ Staff ମଡେଲ୍ ରେ କନଭର୍ଟ କରନ୍ତୁ
    } else {
      throw Exception("Failed to load staff details");
    }
  }

  Future<Response> addAdminStaff(
    Map<String, dynamic> data,
    XFile? image,
  ) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    if (image != null) {
      formData.files.add(MapEntry('profile', (await _getXFilePart(image))!));
    }

    return _request(
      () => _dio.post('/admin/staffs', data: formData, options: opts),
    );
  }

  // 🚀 [NEW]: Update Staff with Image handling
  Future<Response> updateAdminStaff(
    String staffId,
    Map<String, dynamic> data,
    XFile? image,
  ) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    // ଯଦି ୟୁଜର୍ ନୂଆ ଇମେଜ୍ ସିଲେକ୍ଟ କରିଛନ୍ତି, ତେବେ ତାକୁ ଯୋଡନ୍ତୁ
    if (image != null) {
      final imagePart = await _getXFilePart(image);
      if (imagePart != null) {
        formData.files.add(MapEntry('profile', imagePart));
      }
    }

    return _request(
      () => _dio.put(
        '/admin/staffs/$staffId', // ଆପଣଙ୍କ ବ୍ୟାକେଣ୍ଡ୍ ର ଅପଡେଟ୍ ରାଉଟ୍ (Route)
        data: formData,
        options: opts,
      ),
    );
  }

  Future<Response> updateAdminStaffStatus(
    String staffId,
    Map<String, dynamic> statusData,
  ) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    return _request(
      () => _dio.put(
        '/admin/staffs/$staffId/status', // 🚀 $staffId properly interpolated
        data: statusData,
        options: opts,
      ),
    );
  }

  /// Search and filter staffs based on query and role
  /// [query] - The search text (name, email, phone etc.)
  /// [role] - The role to filter by (e.g., 'receptionist', 'manager', 'all')
  Future<List<dynamic>> searchAdminStaffs({String? query, String? role}) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    final Map<String, dynamic> queryParams = {};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (role != null && role.trim().isNotEmpty && role.toLowerCase() != 'all') {
      queryParams['role'] = role.trim();
    }

    final response = await _request(
      () => _dio.get(
        '/admin/staffs/search', // ଆପଣଙ୍କର backend URL
        queryParameters: queryParams,
        options: opts,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      List<dynamic> rawList = [];

      if (response.data['data'] is List) {
        rawList = response.data['data'];
      } else if (response.data['data'] is Map &&
          response.data['data']['staffs'] is List) {
        rawList = response.data['data']['staffs'];
      } else if (response.data is List) {
        rawList = response.data;
      }

      // 🚀 ଏବେ ଆମେ କୌଣସି Staff କ୍ଲାସ୍ ନଖୋଜି ସିଧା JSON List ଫେରାଉଛୁ
      return rawList;
    } else {
      throw Exception("Failed to search staffs");
    }
  }

  /// ଆଜିର ଡ୍ୟାସବୋର୍ଡ ସମ୍ମରୀ (Dashboard Stats) ଆଣିବା ପାଇଁ
  Future<Response> getTodayDashboardStats({
    String? clinicId,
    String? doctorId,
  }) async {
    // ୧. ସିକ୍ୟୁର୍ ଟୋକେନ୍ ଆଣନ୍ତୁ (ଏହା Header ରେ 'Bearer <token>' ଯୋଡ଼ିଦେବ)
    final opts = await _getAuthOptions(key: 'admin_token');

    // ୨. କ୍ୱେରି ପାରାମିଟର୍ସ (Query Parameters) ପ୍ରସ୍ତୁତ କରନ୍ତୁ
    Map<String, dynamic> queryParams = {};
    if (clinicId != null && clinicId.isNotEmpty) {
      queryParams['clinic_id'] = clinicId;
    }
    if (doctorId != null && doctorId.isNotEmpty) {
      queryParams['doctor_id'] = doctorId;
    }

    // ୩. API କଲ୍ କରନ୍ତୁ (ଆପଣଙ୍କ ବ୍ୟାକେଣ୍ଡ୍ ରୁଟ୍ ଅନୁସାରେ ଏଣ୍ଡପଏଣ୍ଟ୍ ନାମ ଦେବେ)
    return _request(
      () => _dio.get(
        '/admin/appointments/dashboard/today', // <-- ଏଠାରେ ନିଜର ପ୍ରକୃତ ବ୍ୟାକେଣ୍ଡ୍ ରୁଟ୍ ଦେବେ
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: opts,
      ),
    );
  }

  // ==========================================================
  // 📊 GET CLINIC/DOCTOR ANALYTICS (Token Based)
  // ==========================================================
  Future<Response> getAnalytics({
    String? date,
    String? month,
    String? clinicId, // 🚀 ସୁପର୍ ଆଡମିନ୍ (Superadmin) ପାଇଁ
    String? doctorId, // 🚀 ନିର୍ଦ୍ଦିଷ୍ଟ ଡାକ୍ତରଙ୍କ ଫିଲ୍ଟର୍ ପାଇଁ
  }) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    Map<String, dynamic> queryParams = {};

    // ୧. ତାରିଖ କିମ୍ବା ମାସ ଫିଲ୍ଟର୍
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (month != null && month.isNotEmpty) queryParams['month'] = month;

    // ୨. ରୋଲ୍-ବେସଡ୍ ଫିଲ୍ଟର୍ (Role-based filters)
    if (clinicId != null && clinicId.isNotEmpty)
      queryParams['clinic_id'] = clinicId;
    if (doctorId != null && doctorId.isNotEmpty)
      queryParams['doctor_id'] = doctorId;

    return _request(
      () => _dio.get(
        '/admin/appointments/analytics', // 🚀 URL ରୁ $id ହଟାଇ ଦିଆଗଲା
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: opts,
      ),
    );
  }

  Future<Response> getActualPatients({
    String? clinicId,
    String? doctorId,
  }) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    // କ୍ୱେରି ପାରାମିଟର୍ସ (Query Parameters) ପ୍ରସ୍ତୁତ କରନ୍ତୁ
    Map<String, dynamic> queryParams = {};
    if (clinicId != null && clinicId.isNotEmpty) {
      queryParams['clinic_id'] = clinicId;
    }
    if (doctorId != null && doctorId.isNotEmpty) {
      queryParams['doctor_id'] = doctorId;
    }

    // ବ୍ୟାକେଣ୍ଡ୍ ରୁଟ୍ ହିସାବରେ URL ଦିଅନ୍ତୁ (ଉଦାହରଣ: '/admin/patients')
    return _request(
      () => _dio.get(
        '/admin/patients',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: opts,
      ),
    );
  }

  Future<Response> getPatientDetails(String phone, {String? name}) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    Map<String, dynamic> queryParams = {};
    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name; // ସଠିକ୍ ରୋଗୀ ବାଛିବା ପାଇଁ (Optional)
    }

    return _request(
      () => _dio.get(
        '/admin/patients/$phone',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: opts,
      ),
    );
  }

  // ==========================================================
  // 🚀 GLOBAL PATIENT SEARCH (For Auto-fill Booking)
  // ==========================================================
  Future<Response> searchDatabaseForBooking(String phone) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    return _request(
      () => _dio.get(
        '/admin/patients/search-by-phone', // 🚀 Option 3 Route (Admin prefix ସହ)
        queryParameters: {
          'phone': phone, // ଫୋନ୍ ନମ୍ବର କ୍ୱେରି ରେ ଯିବ
        },
        options: opts,
      ),
    );
  }

  Future<Response> getAdminDoctors() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/admin/doctors', options: opts));
  }

  Future<Response> getAdminClinicServices() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/clinics/services', options: opts));
  }

  Future<Response> getInsurances() async {
    return _request(() => _dio.get('insurances'));
  }

  // ===========================================================================
  // PARTNER SERVICES API (Add, Get, Update, Delete)
  // ===========================================================================

  // ୧. Add Service (ନୂଆ ସର୍ଭିସ୍ ଯୋଡିବା)
  Future<Response> addPartnerService({required String name}) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    return _request(
      () => _dio.post(
        '/services', // ଆପଣଙ୍କର ପ୍ରକୃତ ବ୍ୟାକଏଣ୍ଡ୍ ରାଉଟ୍ ଅନୁଯାୟୀ ଏହାକୁ ପରିବର୍ତ୍ତନ କରନ୍ତୁ (ଉଦାହରଣ: '/admin/services')
        data: {'name': name},
        options: opts,
      ),
    );
  }

  // ୨. Get Services (ସର୍ଭିସ୍ ତାଲିକା ଆଣିବା)
  // [status] ପାରାମିଟର୍ ଅପ୍ସନାଲ୍ ଅଟେ (SuperAdmin ଫିଲ୍ଟର୍ କରିବା ପାଇଁ ବ୍ୟବହାର କରିପାରିବେ)
  Future<Response> getPartnerServices({String? status}) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    final queryParams = status != null ? {'status': status} : null;

    return _request(
      () => _dio.get('/services', queryParameters: queryParams, options: opts),
    );
  }

  // ୩. Update Service (ସର୍ଭିସ୍ ଏଡିଟ୍ ବା ଆପ୍ରୁଭ୍ କରିବା)
  Future<Response> updatePartnerService({
    required String id,
    required Map<String, dynamic> updateData,
  }) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    return _request(
      () => _dio.put(
        '/services/$id',
        data:
            updateData, // ଉଦାହରଣ: {'status': 'approved', 'isActive': true} କିମ୍ବା {'name': 'New Name'}
        options: opts,
      ),
    );
  }

  // ୪. Delete Service (ସର୍ଭିସ୍ ହଟାଇବା)
  Future<Response> deletePartnerService(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');

    return _request(() => _dio.delete('/services/$id', options: opts));
  }

  // mu aae jae check kari nahi
  Future<Response> updateAdminStaffSlot(Map<String, dynamic> data) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(
      () => _dio.put('/staffs/edit/slots', data: data, options: opts),
    );
  }

  // --- CLINICS ---
  Future<Response> getAdminClinics() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/admin/clinics', options: opts));
  }

  Future<Response> getAdminClinicSlots() async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/clinics/slots', options: opts));
  }

  Future<Response> getClinicDetails(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/admin/clinics/$id', options: opts));
  }

  Future<Response> addAdminClinic(
    Map<String, dynamic> data,
    XFile? logo,
  ) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    if (logo != null) {
      formData.files.add(MapEntry('logo', (await _getXFilePart(logo))!));
    }

    return _request(
      () => _dio.post('/admin/clinics', data: formData, options: opts),
    );
  }

  Future<Response> updateAdminClinic(
    String id,
    Map<String, dynamic> data,
    XFile? logo,
  ) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    if (logo != null) {
      formData.files.add(MapEntry('logo', (await _getXFilePart(logo))!));
    }

    return _request(
      () => _dio.put('/admin/clinics/$id', data: formData, options: opts),
    );
  }

  Future<Response> deleteClinic(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.delete('/clinics/$id', options: opts));
  }

  // ==========================================
  // ୧. Add Medicine (ଇମେଜ୍ ଏବଂ ଡାଟା ସହିତ)
  // ==========================================
  Future<Response> addMedicine(Map<String, dynamic> data, XFile? image) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    // ଯଦି ୟୁଜର୍ ନୂଆ ଇମେଜ୍ ସିଲେକ୍ଟ କରିଛନ୍ତି, ତେବେ ତାକୁ ଯୋଡନ୍ତୁ
    if (image != null) {
      final imagePart = await _getXFilePart(image);
      if (imagePart != null) {
        // ନୋଟ୍: ବ୍ୟାକଏଣ୍ଡ୍ ରେ ଆପଣଙ୍କର multer ଫିଲ୍ଡ ନାମ 'image' ଅଛି
        formData.files.add(MapEntry('image', imagePart));
      }
    }

    return _request(
      () => _dio.post('/medicines/add', data: formData, options: opts),
    );
  }

  // ==========================================
  // ୨. Update Medicine (ଇମେଜ୍ ଏବଂ ଡାଟା ସହିତ)
  // ==========================================
  Future<Response> updateMedicine({
    required String id,
    required Map<String, dynamic> data,
    XFile? image,
  }) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final formData = FormData.fromMap(data);

    // ଯଦି ଏଡିଟ୍ କରିବା ସମୟରେ ନୂଆ ଫଟୋ ଅପଲୋଡ୍ ହୋଇଛି
    if (image != null) {
      final imagePart = await _getXFilePart(image);
      if (imagePart != null) {
        formData.files.add(MapEntry('image', imagePart));
      }
    }

    return _request(
      () => _dio.put('/medicines/update/$id', data: formData, options: opts),
    );
  }

  // ==========================================
  // ୩. Delete Medicine (Soft Delete)
  // ==========================================
  Future<Response> deleteMedicine(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.delete('/medicines/delete/$id', options: opts));
  }

  // ==========================================
  // ୪. Get All Medicines
  // ==========================================
  Future<Response> getAllMedicines({String? search}) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    final queryParams = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    return _request(
      () => _dio.get(
        '/medicines/all',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: opts,
      ),
    );
  }

  // ==========================================
  // ୫. Get Medicine Details
  // ==========================================
  Future<Response> getMedicineDetails(String id) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(() => _dio.get('/medicines/$id', options: opts));
  }

  // ==========================================
  // ୬. Lookup Barcode
  // ==========================================
  Future<Response> lookupBarcode(String barcode) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(
      () => _dio.get('/medicines/lookup/$barcode', options: opts),
    );
  }

  // ==========================================
  // ୭. Update Batch Stock
  // ==========================================
  Future<Response> updateBatchStock({
    required String medicineId,
    required String batchId,
    required Map<String, dynamic> batchData,
  }) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return _request(
      () => _dio.put(
        '/medicines/batch-stock/$medicineId/$batchId',
        data: {'items': batchData},
        options: opts,
      ),
    );
  }

  // ==========================================
  // ୧. CREATE BILL (Invoice ତିଆରି କରିବା ପାଇଁ)
  // ରାଉଟ୍: POST /invoices/
  // ==========================================
  Future<Response> createInvoice(Map<String, dynamic> payload) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return await _dio.post(
      'invoices', // ଆପଣଙ୍କର router.post("/", createBilling) ହିସାବରେ
      data: payload,
      options: opts,
    );
  }

  // ==========================================
  // ୨. GET ALL INVOICES (ସବୁ ବିଲ୍ ଲିଷ୍ଟ୍ ଆଣିବା ପାଇଁ)
  // ରାଉଟ୍: GET /invoices/
  // ==========================================
  Future<Response> getAllInvoices({required String tokenKey}) async {
    final opts = await _getAuthOptions(key: tokenKey);
    return await _dio.get(
      'invoices', // ଆପଣଙ୍କର router.get("/", getInvoices) ହିସାବରେ
      options: opts,
    );
  }

  // ==========================================
  // ୩. GET SINGLE INVOICE DETAILS (ଗୋଟିଏ ବିଲ୍ ର ପୂରା ତଥ୍ୟ ଆଣିବା ପାଇଁ)
  // ରାଉଟ୍: GET /invoices/:id
  // ==========================================
  Future<Response> getInvoiceById(String invoiceId) async {
    final opts = await _getAuthOptions(key: 'admin_token');
    return await _dio.get(
      'invoices/$invoiceId', // ଆପଣଙ୍କର router.get("/:id", getInvoiceDetails) ହିସାବରେ
      options: opts,
    );
  }
}
