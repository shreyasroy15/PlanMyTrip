import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserListNotifier extends Notifier<List<UserModel>> {
  @override
  List<UserModel> build() {
    return [
      UserModel(
        uid: 'usr_001',
        name: 'Alex Johnson',
        email: 'alex@example.com',
        phone: '+1 555 019 2831',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        role: 'user',
        isActive: true,
        createdAt: '2026-01-15T08:00:00Z',
        updatedAt: '2026-09-01T10:00:00Z',
      ),
      UserModel(
        uid: 'usr_002',
        name: 'Sophia Smith',
        email: 'sophia@example.com',
        phone: '+1 555 014 9921',
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        role: 'admin',
        isActive: true,
        createdAt: '2026-02-01T09:30:00Z',
        updatedAt: '2026-09-05T14:20:00Z',
      ),
      UserModel(
        uid: 'usr_003',
        name: 'Michael Brown',
        email: 'michael@example.com',
        phone: '+1 555 018 7734',
        photoUrl: '',
        role: 'user',
        isActive: false,
        createdAt: '2026-03-10T11:15:00Z',
        updatedAt: '2026-08-20T16:00:00Z',
      ),
      UserModel(
        uid: 'usr_004',
        name: 'Elena Rostova',
        email: 'elena@example.com',
        phone: '+1 555 012 3344',
        photoUrl: '',
        role: 'user',
        isActive: true,
        createdAt: '2026-04-12T14:00:00Z',
        updatedAt: '2026-09-02T11:00:00Z',
      ),
    ];
  }

  void toggleUserActive(String uid) {
    state = [
      for (final user in state)
        if (user.uid == uid)
          user.copyWith(isActive: !user.isActive)
        else
          user
    ];
  }

  void deleteUser(String uid) {
    state = state.where((u) => u.uid != uid).toList();
  }

  void changeUserRole(String uid, String newRole) {
    state = [
      for (final user in state)
        if (user.uid == uid)
          user.copyWith(role: newRole)
        else
          user
    ];
  }

  void addUser(UserModel user) {
    state = [...state, user];
  }

  String exportUsersJson() {
    final listMap = state.map((u) => u.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(listMap);
  }

  String exportUsersCsv() {
    final buffer = StringBuffer();
    buffer.writeln('uid,name,email,phone,role,isActive,createdAt,updatedAt');
    for (final u in state) {
      buffer.writeln(
        '"${u.uid}","${u.name}","${u.email}","${u.phone}","${u.role}",${u.isActive},"${u.createdAt}","${u.updatedAt}"',
      );
    }
    return buffer.toString();
  }
}

final userListProvider = NotifierProvider<UserListNotifier, List<UserModel>>(UserListNotifier.new);
