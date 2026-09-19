import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/partner_repository.dart';
import '../value_objects/partner_category.dart';

class CreatePartnerUseCase {
  const CreatePartnerUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, String>> call({
    required String displayName,
    required PartnerCategory category,
    String? companyName,
    String? phone,
    String? phoneSecondary,
    String? whatsappPhone,
    String? address,
    String? city,
    String? contactPerson,
    String? taxId,
    String? serviceDescription,
    String? priceNote,
    int? trustRating,
    String? notes,
  }) {
    return _repository.createPartner(
      displayName: displayName,
      category: category,
      companyName: companyName,
      phone: phone,
      phoneSecondary: phoneSecondary,
      whatsappPhone: whatsappPhone,
      address: address,
      city: city,
      contactPerson: contactPerson,
      taxId: taxId,
      serviceDescription: serviceDescription,
      priceNote: priceNote,
      trustRating: trustRating,
      notes: notes,
    );
  }
}
