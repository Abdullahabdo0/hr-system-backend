import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/salary_payment.dart';
import '../models/performance_review.dart';
import '../models/audit_log.dart';
import '../models/job_applicant.dart';
import '../models/communication.dart';
import '../models/notification.dart';

class ApiService {
  static const String baseUrl =
      'https://hr-system-backend-production-c02d.up.railway.app/api';

  // Auth
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<User?> register(
    String username,
    String password,
    String role, {
    int? employeeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
        'employee_id': employeeId,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(response.body));
    }
    return null;
  }

  // Employees
  Future<List<Employee>> getEmployees() async {
    final response = await http.get(Uri.parse('$baseUrl/employees'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Employee.fromMap(json)).toList();
    }
    return [];
  }

  Future<Employee?> getEmployeeById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/employees/$id'));
    if (response.statusCode == 200) {
      return Employee.fromMap(jsonDecode(response.body));
    }
    return null;
  }

  Future<int> addEmployee(Employee employee) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(employee.toMap()),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    }
    throw Exception('Failed to add employee');
  }

  Future<void> updateEmployee(Employee employee) async {
    final response = await http.put(
      Uri.parse('$baseUrl/employees/${employee.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(employee.toMap()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update employee');
    }
  }

  Future<String?> uploadImage(int employeeId, String filePath, {bool isWeb = false, List<int>? bytes, String? filename}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/employees/upload-image/$employeeId'));
    
    if (isWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename ?? 'profile.jpg',
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
    }
    return null;
  }

  Future<void> deleteEmployee(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/employees/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete employee');
    }
  }

  // Attendance
  Future<List<Attendance>> getAttendanceRecords() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Attendance.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> checkIn(int employeeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'employee_id': employeeId.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to check in');
    }
  }

  Future<void> checkOut(int employeeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'employee_id': employeeId.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to check out');
    }
  }

  // Leaves
  Future<List<Leave>> getLeaves({int? employeeId}) async {
    String url = '$baseUrl/leaves';
    if (employeeId != null) {
      url += '?employee_id=$employeeId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Leave.fromMap(json)).toList();
    }
    return [];
  }

  Future<int> requestLeave(Leave leave) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leaves'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(leave.toMap()),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    }
    throw Exception('Failed to request leave');
  }

  Future<void> approveLeave(int leaveId, int approvedBy) async {
    final response = await http.put(
      Uri.parse('$baseUrl/leaves/$leaveId/approve'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'approved_by': approvedBy.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve leave');
    }
  }

  Future<void> rejectLeave(int leaveId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/leaves/$leaveId/reject'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject leave');
    }
  }

  // Salary
  Future<List<SalaryPayment>> getSalaryPayments({int? employeeId}) async {
    String url = '$baseUrl/salary';
    if (employeeId != null) {
      url += '?employee_id=$employeeId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SalaryPayment.fromMap(json)).toList();
    }
    return [];
  }

  Future<int> addSalaryPayment(SalaryPayment payment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payment.toMap()),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    }
    throw Exception('Failed to add salary payment');
  }

  Future<void> deleteSalaryPayment(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/salary/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete salary payment');
    }
  }

  // Performance
  Future<List<PerformanceReview>> getPerformanceReviews({
    int? employeeId,
  }) async {
    String url = '$baseUrl/performance';
    if (employeeId != null) {
      url += '?employee_id=$employeeId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PerformanceReview.fromMap(json)).toList();
    }
    return [];
  }

  Future<int> addPerformanceReview(PerformanceReview review) async {
    final response = await http.post(
      Uri.parse('$baseUrl/performance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(review.toMap()),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    }
    throw Exception('Failed to add performance review');
  }

  Future<void> deletePerformanceReview(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/performance/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete performance review');
    }
  }

  // Audit
  Future<List<AuditLog>> getAuditLogs() async {
    final response = await http.get(Uri.parse('$baseUrl/audit'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AuditLog.fromMap(json)).toList();
    }
    return [];
  }

  // Job Applicants
  Future<List<JobApplicant>> getJobApplicants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/applicants'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => JobApplicant.fromMap(json)).toList();
      }
    } catch (e) {
      // Fallback to mock data if endpoint doesn't exist
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        JobApplicant(id: 1, name: 'أحمد محمد علي', position: 'محاسب', email: 'ahmed@email.com', phone: '01012345678', status: 'new', appliedAt: DateTime.now().subtract(const Duration(days: 2))),
        JobApplicant(id: 2, name: 'سارة عبد الرحمن', position: 'موظف مخزن', email: 'sara@email.com', phone: '01212345678', status: 'reviewing', appliedAt: DateTime.now().subtract(const Duration(days: 3))),
      ];
    }
    return [];
  }

  // Communications
  Future<List<Communication>> getCommunications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/communications'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Communication.fromMap(json)).toList();
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Communication(id: 1, title: 'طلب شراء مواد', sender: 'قسم المخازن', receiver: 'الإدارة', content: 'نرجو الموافقة...', type: 'purchase_request', status: 'pending', createdAt: DateTime.now()),
        Communication(id: 2, title: 'نقل موظف', sender: 'الموارد البشرية', receiver: 'المدير', content: 'بخصوص الموظف...', type: 'message', status: 'replied', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
      ];
    }
    return [];
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromMap(json)).toList();
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        NotificationModel(id: 1, title: 'تم اعتماد طلب الشراء', content: 'تمت الموافقة على طلبك رقم 101', type: 'system', createdAt: DateTime.now().subtract(const Duration(minutes: 15))),
        NotificationModel(id: 2, title: 'تذكير بالاجتماع', content: 'اجتماع الساعة 10 صباحاً', type: 'event', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      ];
    }
    return [];
  }
}
