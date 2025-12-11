// models/user_model.dart
class User {
  final String id;
  final String username;
  final String phone;
  final String email;
  final String password;
  final int type;
  final int empType;
  final String state;
  final String statename;
  final String city;
  final String address;
  final int verified;
  final String pincode;
  final String dob;
  final String about;
  final List<String> department;
  final String doc1;
  final String doc2;
  final String doc3;
  final String profile;
  final String pHealthHistory;
  final String cHealthStatus;
  final List<String> coverage;
  final List<String> gallery;
  final List<String> images;
  final List<String> mId;
  final List<String> dynamicUsers;
  final int wallet;
  final String longitude;
  final String latitude;
  final List<String> calls;
  final String status;
  final List<String> orders;
  final String createdAt;
  final String updatedAt;
  final int v;

  User({
    required this.id,
    required this.username,
    required this.phone,
    required this.email,
    required this.password,
    required this.type,
    required this.empType,
    required this.state,
    required this.statename,
    required this.city,
    required this.address,
    required this.verified,
    required this.pincode,
    required this.dob,
    required this.about,
    required this.department,
    required this.doc1,
    required this.doc2,
    required this.doc3,
    required this.profile,
    required this.pHealthHistory,
    required this.cHealthStatus,
    required this.coverage,
    required this.gallery,
    required this.images,
    required this.mId,
    required this.dynamicUsers,
    required this.wallet,
    required this.longitude,
    required this.latitude,
    required this.calls,
    required this.status,
    required this.orders,
    required this.createdAt,
    required this.updatedAt,
    required this.v, required String cHealthHistory,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      type: json['type'] ?? 0,
      empType: json['empType'] ?? 0,
      state: json['state'] ?? '',
      statename: json['statename'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      verified: json['verified'] ?? 0,
      pincode: json['pincode'] ?? '',
      dob: json['DOB'] ?? '',
      about: json['about'] ?? '',
      department: List<String>.from(json['department'] ?? []),
      doc1: json['Doc1'] ?? '',
      doc2: json['Doc2'] ?? '',
      doc3: json['Doc3'] ?? '',
      profile: json['profile'] ?? '',
      pHealthHistory: json['pHealthHistory'] ?? '',
      cHealthStatus: json['cHealthStatus'] ?? '',
      coverage: List<String>.from(json['coverage'] ?? []),
      gallery: List<String>.from(json['gallery'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      mId: List<String>.from(json['mId'] ?? []),
      dynamicUsers: List<String>.from(json['dynamicUsers'] ?? []),
      wallet: json['wallet'] ?? 0,
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      calls: List<String>.from(json['calls'] ?? []),
      status: json['status'] ?? '',
      orders: List<String>.from(json['orders'] ?? []),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      v: json['__v'] ?? 0, cHealthHistory: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'phone': phone,
      'email': email,
      'password': password,
      'type': type,
      'empType': empType,
      'state': state,
      'statename': statename,
      'city': city,
      'address': address,
      'verified': verified,
      'pincode': pincode,
      'DOB': dob,
      'about': about,
      'department': department,
      'Doc1': doc1,
      'Doc2': doc2,
      'Doc3': doc3,
      'profile': profile,
      'pHealthHistory': pHealthHistory,
      'cHealthStatus': cHealthStatus,
      'coverage': coverage,
      'gallery': gallery,
      'images': images,
      'mId': mId,
      'dynamicUsers': dynamicUsers,
      'wallet': wallet,
      'longitude': longitude,
      'latitude': latitude,
      'calls': calls,
      'status': status,
      'orders': orders,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? phone,
    String? email,
    String? password,
    int? type,
    int? empType,
    String? state,
    String? statename,
    String? city,
    String? address,
    int? verified,
    String? pincode,
    String? dob,
    String? about,
    List<String>? department,
    String? doc1,
    String? doc2,
    String? doc3,
    String? profile,
    String? pHealthHistory,
    String? cHealthStatus,
    List<String>? coverage,
    List<String>? gallery,
    List<String>? images,
    List<String>? mId,
    List<String>? dynamicUsers,
    int? wallet,
    String? longitude,
    String? latitude,
    List<String>? calls,
    String? status,
    List<String>? orders,
    String? createdAt,
    String? updatedAt,
    int? v,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      type: type ?? this.type,
      empType: empType ?? this.empType,
      state: state ?? this.state,
      statename: statename ?? this.statename,
      city: city ?? this.city,
      address: address ?? this.address,
      verified: verified ?? this.verified,
      pincode: pincode ?? this.pincode,
      dob: dob ?? this.dob,
      about: about ?? this.about,
      department: department ?? this.department,
      doc1: doc1 ?? this.doc1,
      doc2: doc2 ?? this.doc2,
      doc3: doc3 ?? this.doc3,
      profile: profile ?? this.profile,
      pHealthHistory: pHealthHistory ?? this.pHealthHistory,
      cHealthHistory: cHealthStatus ?? this.cHealthStatus,
      coverage: coverage ?? this.coverage,
      gallery: gallery ?? this.gallery,
      images: images ?? this.images,
      mId: mId ?? this.mId,
      dynamicUsers: dynamicUsers ?? this.dynamicUsers,
      wallet: wallet ?? this.wallet,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      calls: calls ?? this.calls,
      status: status ?? this.status,
      orders: orders ?? this.orders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v, cHealthStatus: '',
    );
  }
}