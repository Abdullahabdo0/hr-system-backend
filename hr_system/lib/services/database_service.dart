import 'package:postgres/postgres.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../models/audit_log.dart';
import '../models/leave.dart';
import '../models/salary_payment.dart';
import '../models/performance_review.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _secureStorage = const FlutterSecureStorage();
  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection != null) {
      try {
        await _connection!.execute('SELECT 1');
        return _connection!;
      } catch (e) {
        _connection = null;
      }
    }
    return await _connect();
  }

  Future<Connection> _connect() async {
    final host = await _secureStorage.read(key: 'db_host') ?? 'localhost';
    final port = int.tryParse(await _secureStorage.read(key: 'db_port') ?? '5432') ?? 5432;
    final database = await _secureStorage.read(key: 'db_name') ?? 'hr_system';
    final username = await _secureStorage.read(key: 'db_user') ?? 'postgres';
    final password = await _secureStorage.read(key: 'db_password') ?? 'postgres';

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    await _initializeDatabase();
    return _connection!;
  }

  Future<void> _initializeDatabase() async {
    final conn = await connection;
    
    // Create employees table first (no dependencies)
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE,
        phone VARCHAR(20),
        position VARCHAR(50),
        department VARCHAR(50),
        hire_date DATE NOT NULL,
        salary DECIMAL(10,2) DEFAULT 0,
        status VARCHAR(20) DEFAULT 'active'
      )
    ''');

    // Create users table (depends on employees)
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        employee_id INTEGER REFERENCES employees(id),
        role VARCHAR(20) DEFAULT 'employee'
      )
    ''');

    // Create attendance table (depends on employees)
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        check_in_time TIMESTAMP,
        check_out_time TIMESTAMP,
        total_hours DECIMAL(5,2) DEFAULT 0,
        status VARCHAR(20) DEFAULT 'present',
        notes TEXT
      )
    ''');

    // Create audit_log table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        action VARCHAR(50) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id INTEGER,
        old_values TEXT,
        new_values TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create leaves table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS leaves (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        leave_type VARCHAR(50) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        reason TEXT,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        approved_at TIMESTAMP,
        approved_by INTEGER REFERENCES users(id)
      )
    ''');

    // Create salary_payments table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS salary_payments (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        amount DECIMAL(10,2) NOT NULL,
        payment_date DATE NOT NULL,
        payment_type VARCHAR(50) DEFAULT 'salary',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create performance_reviews table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS performance_reviews (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        reviewer_id INTEGER REFERENCES users(id),
        review_date DATE NOT NULL,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        comments TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create default admin user if not exists
    final result = await conn.execute(
      "SELECT id FROM users WHERE username = 'admin'"
    );
    
    if (result.isEmpty) {
      await conn.execute(
        "INSERT INTO users (username, password, role) VALUES (\$1, \$2, \$3)",
        parameters: ['admin', 'admin123', 'admin'],
      );
    }
  }

  Future<void> saveDatabaseConfig({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: 'db_host', value: host);
    await _secureStorage.write(key: 'db_port', value: port.toString());
    await _secureStorage.write(key: 'db_name', value: database);
    await _secureStorage.write(key: 'db_user', value: username);
    await _secureStorage.write(key: 'db_password', value: password);
    
    // Reconnect with new config
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    await _connect();
  }

  // User operations
  Future<User?> login(String username, String password) async {
    final conn = await connection;
    final result = await conn.execute(
      "SELECT * FROM users WHERE username = \$1 AND password = \$2",
      parameters: [username, password],
    );

    if (result.isNotEmpty) {
      final row = result.first;
      return User.fromMap({
        'id': row[0],
        'username': row[1],
        'password': row[2],
        'employee_id': row[3],
        'role': row[4],
      });
    }
    return null;
  }

  Future<void> createUser(String username, String password, int employeeId) async {
    final conn = await connection;
    await conn.execute(
      "INSERT INTO users (username, password, employee_id, role) VALUES (\$1, \$2, \$3, \$4)",
      parameters: [username, password, employeeId, 'employee'],
    );
  }

  // Employee operations
  Future<List<Employee>> getEmployees() async {
    final conn = await connection;
    final result = await conn.execute('SELECT * FROM employees ORDER BY id');
    
    return result.map((row) => Employee.fromMap({
      'id': row[0],
      'name': row[1],
      'email': row[2],
      'phone': row[3],
      'position': row[4],
      'department': row[5],
      'hire_date': row[6].toString(),
      'salary': row[7],
      'status': row[8],
    })).toList();
  }

  Future<Employee?> getEmployeeById(int id) async {
    final conn = await connection;
    final result = await conn.execute(
      "SELECT * FROM employees WHERE id = \$1",
      parameters: [id],
    );

    if (result.isNotEmpty) {
      final row = result.first;
      return Employee.fromMap({
        'id': row[0],
        'name': row[1],
        'email': row[2],
        'phone': row[3],
        'position': row[4],
        'department': row[5],
        'hire_date': row[6].toString(),
        'salary': row[7],
        'status': row[8],
      });
    }
    return null;
  }

  Future<int> addEmployee(Employee employee, {int? userId}) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO employees (name, email, phone, position, department, hire_date, salary, status)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
      RETURNING id
      ''',
      parameters: [
        employee.name,
        employee.email,
        employee.phone,
        employee.position,
        employee.department,
        employee.hireDate,
        employee.salary,
        employee.status,
      ],
    );
    final employeeId = result.first[0] as int;

    // Log activity
    await logActivity(
      userId: userId,
      action: 'CREATE',
      entityType: 'Employee',
      entityId: employeeId,
      newValues: employee.toMap().toString(),
    );

    return employeeId;
  }

  Future<void> updateEmployee(Employee employee, {int? userId}) async {
    final conn = await connection;
    
    // Get old values
    final oldResult = await conn.execute(
      "SELECT * FROM employees WHERE id = \$1",
      parameters: [employee.id],
    );
    final oldValues = oldResult.isNotEmpty ? oldResult.first.toString() : null;

    await conn.execute(
      '''
      UPDATE employees 
      SET name = \$1, email = \$2, phone = \$3, position = \$4,
          department = \$5, hire_date = \$6, salary = \$7, status = \$8
      WHERE id = \$9
      ''',
      parameters: [
        employee.name,
        employee.email,
        employee.phone,
        employee.position,
        employee.department,
        employee.hireDate,
        employee.salary,
        employee.status,
        employee.id,
      ],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'UPDATE',
      entityType: 'Employee',
      entityId: employee.id,
      oldValues: oldValues,
      newValues: employee.toMap().toString(),
    );
  }

  Future<void> deleteEmployee(int id, {int? userId}) async {
    final conn = await connection;
    
    // Get old values
    final oldResult = await conn.execute(
      "SELECT * FROM employees WHERE id = \$1",
      parameters: [id],
    );
    final oldValues = oldResult.isNotEmpty ? oldResult.first.toString() : null;

    await conn.execute(
      "DELETE FROM employees WHERE id = \$1",
      parameters: [id],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'DELETE',
      entityType: 'Employee',
      entityId: id,
      oldValues: oldValues,
    );
  }

  // Attendance operations
  Future<List<Attendance>> getAttendanceRecords() async {
    final conn = await connection;
    final result = await conn.execute(
      'SELECT a.*, e.name as employee_name FROM attendance a JOIN employees e ON a.employee_id = e.id ORDER BY a.date DESC, a.check_in_time DESC'
    );
    
    return result.map((row) => Attendance.fromMap({
      'id': row[0],
      'employee_id': row[1],
      'date': row[2].toString(),
      'check_in_time': row[3]?.toString(),
      'check_out_time': row[4]?.toString(),
      'total_hours': row[5],
      'status': row[6],
      'notes': row[7],
    })).toList();
  }

  Future<List<Attendance>> getAttendanceByEmployee(int employeeId) async {
    final conn = await connection;
    final result = await conn.execute(
      "SELECT * FROM attendance WHERE employee_id = \$1 ORDER BY date DESC",
      parameters: [employeeId],
    );
    
    return result.map((row) => Attendance.fromMap({
      'id': row[0],
      'employee_id': row[1],
      'date': row[2].toString(),
      'check_in_time': row[3]?.toString(),
      'check_out_time': row[4]?.toString(),
      'total_hours': row[5],
      'status': row[6],
      'notes': row[7],
    })).toList();
  }

  Future<List<Attendance>> getAttendanceByDateRange(DateTime startDate, DateTime endDate) async {
    final conn = await connection;
    final result = await conn.execute(
      "SELECT * FROM attendance WHERE date BETWEEN \$1 AND \$2 ORDER BY date DESC",
      parameters: [startDate, endDate],
    );
    
    return result.map((row) => Attendance.fromMap({
      'id': row[0],
      'employee_id': row[1],
      'date': row[2].toString(),
      'check_in_time': row[3]?.toString(),
      'check_out_time': row[4]?.toString(),
      'total_hours': row[5],
      'status': row[6],
      'notes': row[7],
    })).toList();
  }

  Future<int> addAttendance(Attendance attendance) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO attendance (employee_id, date, check_in_time, check_out_time, total_hours, status, notes)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)
      RETURNING id
      ''',
      parameters: [
        attendance.employeeId,
        attendance.date,
        attendance.checkInTime,
        attendance.checkOutTime,
        attendance.totalHours,
        attendance.status,
        attendance.notes,
      ],
    );
    return result.first[0] as int;
  }

  Future<void> updateAttendance(Attendance attendance) async {
    final conn = await connection;
    await conn.execute(
      '''
      UPDATE attendance 
      SET check_in_time = \$1, check_out_time = \$2,
          total_hours = \$3, status = \$4, notes = \$5
      WHERE id = \$6
      ''',
      parameters: [
        attendance.checkInTime,
        attendance.checkOutTime,
        attendance.totalHours,
        attendance.status,
        attendance.notes,
        attendance.id,
      ],
    );
  }

  Future<void> deleteAttendance(int id) async {
    final conn = await connection;
    await conn.execute(
      "DELETE FROM attendance WHERE id = \$1",
      parameters: [id],
    );
  }

  Future<void> checkIn(int employeeId, {int? userId}) async {
    final conn = await connection;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already checked in today
    final existing = await conn.execute(
      "SELECT id FROM attendance WHERE employee_id = \$1 AND date = \$2",
      parameters: [employeeId, today],
    );

    if (existing.isEmpty) {
      await conn.execute(
        '''
        INSERT INTO attendance (employee_id, date, check_in_time, status)
        VALUES (\$1, \$2, \$3, 'present')
        ''',
        parameters: [employeeId, today, now],
      );

      // Log activity
      await logActivity(
        userId: userId,
        action: 'CHECK_IN',
        entityType: 'Attendance',
        entityId: employeeId,
        newValues: 'Employee $employeeId checked in at $now',
      );
    }
  }

  Future<void> checkOut(int employeeId, {int? userId}) async {
    final conn = await connection;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = await conn.execute(
      "SELECT id, check_in_time FROM attendance WHERE employee_id = \$1 AND date = \$2",
      parameters: [employeeId, today],
    );

    if (result.isNotEmpty) {
      final row = result.first;
      final id = row[0] as int;
      final checkInTime = row[1] as DateTime;

      final totalHours = now.difference(checkInTime).inMinutes / 60.0;

      await conn.execute(
        '''
        UPDATE attendance
        SET check_out_time = \$1, total_hours = \$2
        WHERE id = \$3
        ''',
        parameters: [now, totalHours, id],
      );

      // Log activity
      await logActivity(
        userId: userId,
        action: 'CHECK_OUT',
        entityType: 'Attendance',
        entityId: employeeId,
        newValues: 'Employee $employeeId checked out at $now, total hours: $totalHours',
      );
    }
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  // Audit Log Functions
  Future<void> logActivity({
    required int? userId,
    required String action,
    required String entityType,
    int? entityId,
    String? oldValues,
    String? newValues,
  }) async {
    final conn = await connection;
    await conn.execute(
      '''
      INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_values, new_values)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6)
      ''',
      parameters: [userId, action, entityType, entityId, oldValues, newValues],
    );
  }

  Future<List<AuditLog>> getAuditLogs() async {
    final conn = await connection;
    final result = await conn.execute('''
      SELECT al.*, u.username, e.name as employee_name
      FROM audit_log al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN employees e ON u.employee_id = e.id
      ORDER BY al.created_at DESC
      LIMIT 100
    ''');

    return result.map((row) {
      return AuditLog(
        id: row[0] as int?,
        userId: row[1] as int?,
        action: row[2] as String,
        entityType: row[3] as String,
        entityId: row[4] as int?,
        oldValues: row[5] as String?,
        newValues: row[6] as String?,
        createdAt: DateTime.parse(row[7] as String),
      );
    }).toList();
  }

  // Email validation
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Leave Management Functions
  Future<int> requestLeave(Leave leave, {int? userId}) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO leaves (employee_id, leave_type, start_date, end_date, reason, status)
      VALUES (\$1, \$2, \$3, \$4, \$5, 'pending')
      RETURNING id
      ''',
      parameters: [
        leave.employeeId,
        leave.leaveType,
        leave.startDate,
        leave.endDate,
        leave.reason,
      ],
    );
    final leaveId = result.first[0] as int;

    // Log activity
    await logActivity(
      userId: userId,
      action: 'REQUEST_LEAVE',
      entityType: 'Leave',
      entityId: leaveId,
      newValues: leave.toMap().toString(),
    );

    return leaveId;
  }

  Future<List<Leave>> getLeaves({int? employeeId}) async {
    final conn = await connection;
    String query = '''
      SELECT l.*, e.name as employee_name
      FROM leaves l
      JOIN employees e ON l.employee_id = e.id
    ''';
    
    if (employeeId != null) {
      query += ' WHERE l.employee_id = \$1';
    }
    
    query += ' ORDER BY l.created_at DESC';

    final result = await conn.execute(
      query,
      parameters: employeeId != null ? [employeeId] : [],
    );

    return result.map((row) {
      return Leave(
        id: row[0] as int?,
        employeeId: row[1] as int,
        leaveType: row[2] as String,
        startDate: DateTime.parse(row[3] as String),
        endDate: DateTime.parse(row[4] as String),
        reason: row[5] as String?,
        status: row[6] as String,
        createdAt: DateTime.parse(row[7] as String),
        approvedAt: row[8] != null ? DateTime.parse(row[8] as String) : null,
        approvedBy: row[9] as int?,
      );
    }).toList();
  }

  Future<void> approveLeave(int leaveId, int approvedBy, {int? userId}) async {
    final conn = await connection;
    final now = DateTime.now();
    
    await conn.execute(
      '''
      UPDATE leaves
      SET status = 'approved', approved_at = \$1, approved_by = \$2
      WHERE id = \$3
      ''',
      parameters: [now, approvedBy, leaveId],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'APPROVE_LEAVE',
      entityType: 'Leave',
      entityId: leaveId,
      newValues: 'Leave $leaveId approved by user $approvedBy',
    );
  }

  Future<void> rejectLeave(int leaveId, {int? userId}) async {
    final conn = await connection;
    
    await conn.execute(
      '''
      UPDATE leaves
      SET status = 'rejected'
      WHERE id = \$1
      ''',
      parameters: [leaveId],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'REJECT_LEAVE',
      entityType: 'Leave',
      entityId: leaveId,
      newValues: 'Leave $leaveId rejected',
    );
  }

  // Salary Payment Functions
  Future<int> addSalaryPayment(SalaryPayment payment, {int? userId}) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO salary_payments (employee_id, amount, payment_date, payment_type, notes)
      VALUES (\$1, \$2, \$3, \$4, \$5)
      RETURNING id
      ''',
      parameters: [
        payment.employeeId,
        payment.amount,
        payment.paymentDate,
        payment.paymentType,
        payment.notes,
      ],
    );
    final paymentId = result.first[0] as int;

    // Log activity
    await logActivity(
      userId: userId,
      action: 'ADD_PAYMENT',
      entityType: 'SalaryPayment',
      entityId: paymentId,
      newValues: payment.toMap().toString(),
    );

    return paymentId;
  }

  Future<List<SalaryPayment>> getSalaryPayments({int? employeeId}) async {
    final conn = await connection;
    String query = '''
      SELECT sp.*, e.name as employee_name
      FROM salary_payments sp
      JOIN employees e ON sp.employee_id = e.id
    ''';
    
    if (employeeId != null) {
      query += ' WHERE sp.employee_id = \$1';
    }
    
    query += ' ORDER BY sp.payment_date DESC';

    final result = await conn.execute(
      query,
      parameters: employeeId != null ? [employeeId] : [],
    );

    return result.map((row) {
      return SalaryPayment(
        id: row[0] as int?,
        employeeId: row[1] as int,
        amount: row[2] as double,
        paymentDate: DateTime.parse(row[3] as String),
        paymentType: row[4] as String? ?? 'salary',
        notes: row[5] as String?,
        createdAt: DateTime.parse(row[6] as String),
      );
    }).toList();
  }

  Future<void> deleteSalaryPayment(int id, {int? userId}) async {
    final conn = await connection;
    
    // Get old values
    final oldResult = await conn.execute(
      "SELECT * FROM salary_payments WHERE id = \$1",
      parameters: [id],
    );
    final oldValues = oldResult.isNotEmpty ? oldResult.first.toString() : null;

    await conn.execute(
      "DELETE FROM salary_payments WHERE id = \$1",
      parameters: [id],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'DELETE_PAYMENT',
      entityType: 'SalaryPayment',
      entityId: id,
      oldValues: oldValues,
    );
  }

  // Performance Review Functions
  Future<int> addPerformanceReview(PerformanceReview review, {int? userId}) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO performance_reviews (employee_id, reviewer_id, review_date, rating, comments)
      VALUES (\$1, \$2, \$3, \$4, \$5)
      RETURNING id
      ''',
      parameters: [
        review.employeeId,
        review.reviewerId,
        review.reviewDate,
        review.rating,
        review.comments,
      ],
    );
    final reviewId = result.first[0] as int;

    // Log activity
    await logActivity(
      userId: userId,
      action: 'ADD_REVIEW',
      entityType: 'PerformanceReview',
      entityId: reviewId,
      newValues: review.toMap().toString(),
    );

    return reviewId;
  }

  Future<List<PerformanceReview>> getPerformanceReviews({int? employeeId}) async {
    final conn = await connection;
    String query = '''
      SELECT pr.*, e.name as employee_name, u.username as reviewer_name
      FROM performance_reviews pr
      JOIN employees e ON pr.employee_id = e.id
      LEFT JOIN users u ON pr.reviewer_id = u.id
    ''';
    
    if (employeeId != null) {
      query += ' WHERE pr.employee_id = \$1';
    }
    
    query += ' ORDER BY pr.review_date DESC';

    final result = await conn.execute(
      query,
      parameters: employeeId != null ? [employeeId] : [],
    );

    return result.map((row) {
      return PerformanceReview(
        id: row[0] as int?,
        employeeId: row[1] as int,
        reviewerId: row[2] as int?,
        reviewDate: DateTime.parse(row[3] as String),
        rating: row[4] as int,
        comments: row[5] as String?,
        createdAt: DateTime.parse(row[6] as String),
      );
    }).toList();
  }

  Future<void> deletePerformanceReview(int id, {int? userId}) async {
    final conn = await connection;
    
    // Get old values
    final oldResult = await conn.execute(
      "SELECT * FROM performance_reviews WHERE id = \$1",
      parameters: [id],
    );
    final oldValues = oldResult.isNotEmpty ? oldResult.first.toString() : null;

    await conn.execute(
      "DELETE FROM performance_reviews WHERE id = \$1",
      parameters: [id],
    );

    // Log activity
    await logActivity(
      userId: userId,
      action: 'DELETE_REVIEW',
      entityType: 'PerformanceReview',
      entityId: id,
      oldValues: oldValues,
    );
  }
}
