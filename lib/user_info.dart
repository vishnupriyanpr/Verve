class UserInfo {
  String? fullName;
  String? age;
  String? height;
  String? weight;
  String? gender; // New field for gender
  String? disease;
  String? goal;
  String? foodPreference;
  String? allergies;

  UserInfo({
    this.fullName,
    this.age,
    this.height,
    this.weight,
    this.gender, // Include gender in the constructor
    this.disease,
    this.goal,
    this.foodPreference,
    this.allergies,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender, // Save gender to Firestore
      'disease': disease,
      'goal': goal,
      'foodPreference': foodPreference,
      'allergies': allergies,
    };
  }
}
