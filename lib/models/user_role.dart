enum UserRole {
  admin,
  staff,
  doctor,
  nurse,
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Administrator';
    case UserRole.staff:
      return 'Personal';
    case UserRole.doctor:
      return 'Medic';
    case UserRole.nurse:
      return 'Asistent';
  }
}

UserRole stringToUserRole(String value) {
  switch (value) {
    case 'Administrator':
      return UserRole.admin;
    case 'Medic':
      return UserRole.doctor;
    case 'Asistent':
      return UserRole.nurse;
    default:
      return UserRole.staff;
  }
}
