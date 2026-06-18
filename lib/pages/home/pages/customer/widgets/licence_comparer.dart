import 'package:ocean_rent/models/user_model.dart';

class LicenseComparer {
  static const Map<String, int> licenseLevels = {'none': 0, 'pnb': 1, 'per': 2};

  static bool canDriveBoat({
    required NauticalLicense? nauticalLicense,
    required String requiredLicense,
  }) {
    if (nauticalLicense == null || nauticalLicense.status != 'verified') {
      return requiredLicense.toLowerCase() == 'none';
    }

    final userLevel = licenseLevels[nauticalLicense.type.toLowerCase()] ?? 0;

    final boatLevel = licenseLevels[requiredLicense.toLowerCase()] ?? 0;

    return userLevel >= boatLevel;
  }
}
