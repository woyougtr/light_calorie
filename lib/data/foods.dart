// 食物数据库 v1.0
// 数据来源：中国食物成分表（GB 5009.3）+ USDA

class Food {
  final String id;
  final String name;
  final String category;
  final double caloriePer100g; // 每100g热量（大卡）
  final double proteinPer100g; // 每100g蛋白质（g）
  final double carbPer100g; // 每100g碳水（g）
  final double fatPer100g; // 每100g脂肪（g）
  final String icon;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriePer100g,
    this.proteinPer100g = 0,
    this.carbPer100g = 0,
    this.fatPer100g = 0,
    this.icon = '🍽️',
  });

  double calorieFor(double grams) => (caloriePer100g * grams / 100).roundToDouble();
}

class FoodCategory {
  static const String staple = '主食';
  static const String meat = '肉类';
  static const String egg = '蛋类';
  static const String seafood = '水产';
  static const String vegetable = '蔬菜';
  static const String fruit = '水果';
  static const String dairy = '奶制品';
  static const String snack = '零食';
  static const String drink = '饮料';
  static const String other = '其他';
}

// 内置食物数据库 ~150种
const List<Food> foodDatabase = [
  // ========== 主食 ==========
  Food(id: 'f001', name: '糙米饭', category: FoodCategory.staple, caloriePer100g: 110, proteinPer100g: 2.6, carbPer100g: 23, fatPer100g: 0.8, icon: '🍚'),
  Food(id: 'f002', name: '白米饭', category: FoodCategory.staple, caloriePer100g: 116, proteinPer100g: 2.6, carbPer100g: 25.9, fatPer100g: 0.3, icon: '🍚'),
  Food(id: 'f003', name: '杂粮饭', category: FoodCategory.staple, caloriePer100g: 118, proteinPer100g: 2.8, carbPer100g: 24, fatPer100g: 0.5, icon: '🍚'),
  Food(id: 'f004', name: '燕麦片', category: FoodCategory.staple, caloriePer100g: 389, proteinPer100g: 13.2, carbPer100g: 67.7, fatPer100g: 6.5, icon: '🌾'),
  Food(id: 'f005', name: '全麦面包', category: FoodCategory.staple, caloriePer100g: 250, proteinPer100g: 10, carbPer100g: 41, fatPer100g: 3.4, icon: '🍞'),
  Food(id: 'f006', name: '白面包', category: FoodCategory.staple, caloriePer100g: 265, proteinPer100g: 8, carbPer100g: 49, fatPer100g: 3.2, icon: '🍞'),
  Food(id: 'f007', name: '荞麦面', category: FoodCategory.staple, caloriePer100g: 304, proteinPer100g: 10, carbPer100g: 60, fatPer100g: 2.5, icon: '🍜'),
  Food(id: 'f008', name: '挂面', category: FoodCategory.staple, caloriePer100g: 350, proteinPer100g: 12, carbPer100g: 70, fatPer100g: 1.5, icon: '🍜'),
  Food(id: 'f009', name: '馒头', category: FoodCategory.staple, caloriePer100g: 223, proteinPer100g: 7, carbPer100g: 47, fatPer100g: 1.1, icon: '🥖'),
  Food(id: 'f010', name: '包子（肉）', category: FoodCategory.staple, caloriePer100g: 227, proteinPer100g: 9, carbPer100g: 30, fatPer100g: 8, icon: '🥟'),
  Food(id: 'f011', name: '饺子（猪肉）', category: FoodCategory.staple, caloriePer100g: 242, proteinPer100g: 10, carbPer100g: 25, fatPer100g: 12, icon: '🥟'),
  Food(id: 'f012', name: '煎饼', category: FoodCategory.staple, caloriePer100g: 299, proteinPer100g: 7, carbPer100g: 50, fatPer100g: 8, icon: '🥞'),
  Food(id: 'f013', name: '油条', category: FoodCategory.staple, caloriePer100g: 386, proteinPer100g: 6, carbPer100g: 51, fatPer100g: 18, icon: '🍳'),
  Food(id: 'f014', name: '红薯', category: FoodCategory.staple, caloriePer100g: 99, proteinPer100g: 1.1, carbPer100g: 24, fatPer100g: 0.1, icon: '🍠'),
  Food(id: 'f015', name: '土豆', category: FoodCategory.staple, caloriePer100g: 76, proteinPer100g: 2, carbPer100g: 17, fatPer100g: 0.1, icon: '🥔'),
  Food(id: 'f016', name: '玉米', category: FoodCategory.staple, caloriePer100g: 112, proteinPer100g: 4, carbPer100g: 23, fatPer100g: 1.2, icon: '🌽'),
  Food(id: 'f017', name: '小米粥', category: FoodCategory.staple, caloriePer100g: 46, proteinPer100g: 1.4, carbPer100g: 9, fatPer100g: 0.3, icon: '🥣'),
  Food(id: 'f018', name: '八宝粥', category: FoodCategory.staple, caloriePer100g: 65, proteinPer100g: 1.5, carbPer100g: 13, fatPer100g: 0.5, icon: '🥣'),
  Food(id: 'f019', name: '方便面', category: FoodCategory.staple, caloriePer100g: 473, proteinPer100g: 10, carbPer100g: 60, fatPer100g: 22, icon: '🍜'),
  Food(id: 'f020', name: '烧饼', category: FoodCategory.staple, caloriePer100g: 257, proteinPer100g: 8, carbPer100g: 47, fatPer100g: 4.5, icon: '🥙'),
  // ========== 肉类 ==========
  Food(id: 'f101', name: '猪里脊肉', category: FoodCategory.meat, caloriePer100g: 155, proteinPer100g: 20, carbPer100g: 1, fatPer100g: 8, icon: '🥩'),
  Food(id: 'f102', name: '猪五花肉', category: FoodCategory.meat, caloriePer100g: 395, proteinPer100g: 13, carbPer100g: 0, fatPer100g: 37, icon: '🥩'),
  Food(id: 'f103', name: '猪排', category: FoodCategory.meat, caloriePer100g: 260, proteinPer100g: 18, carbPer100g: 0, fatPer100g: 21, icon: '🥩'),
  Food(id: 'f104', name: '牛肉（瘦）', category: FoodCategory.meat, caloriePer100g: 106, proteinPer100g: 20, carbPer100g: 1, fatPer100g: 3, icon: '🥩'),
  Food(id: 'f105', name: '牛腩', category: FoodCategory.meat, caloriePer100g: 246, proteinPer100g: 16, carbPer100g: 0, fatPer100g: 20, icon: '🥩'),
  Food(id: 'f106', name: '牛排', category: FoodCategory.meat, caloriePer100g: 271, proteinPer100g: 18, carbPer100g: 0, fatPer100g: 22, icon: '🥩'),
  Food(id: 'f107', name: '羊肉（瘦）', category: FoodCategory.meat, caloriePer100g: 118, proteinPer100g: 20, carbPer100g: 0, fatPer100g: 4, icon: '🥩'),
  Food(id: 'f108', name: '鸡胸肉', category: FoodCategory.meat, caloriePer100g: 133, proteinPer100g: 24, carbPer100g: 0, fatPer100g: 3.5, icon: '🍗'),
  Food(id: 'f109', name: '鸡腿肉', category: FoodCategory.meat, caloriePer100g: 181, proteinPer100g: 21, carbPer100g: 0, fatPer100g: 11, icon: '🍗'),
  Food(id: 'f110', name: '鸡翅', category: FoodCategory.meat, caloriePer100g: 203, proteinPer100g: 18, carbPer100g: 0, fatPer100g: 14, icon: '🍗'),
  Food(id: 'f111', name: '鸭肉', category: FoodCategory.meat, caloriePer100g: 240, proteinPer100g: 16, carbPer100g: 0, fatPer100g: 19, icon: '🦆'),
  Food(id: 'f112', name: '腊肉', category: FoodCategory.meat, caloriePer100g: 498, proteinPer100g: 12, carbPer100g: 2, fatPer100g: 49, icon: '🥓'),
  Food(id: 'f113', name: '火腿', category: FoodCategory.meat, caloriePer100g: 270, proteinPer100g: 17, carbPer100g: 2, fatPer100g: 21, icon: '🥓'),
  Food(id: 'f114', name: '香肠', category: FoodCategory.meat, caloriePer100g: 290, proteinPer100g: 12, carbPer100g: 2, fatPer100g: 26, icon: '🌭'),
  Food(id: 'f115', name: '培根', category: FoodCategory.meat, caloriePer100g: 326, proteinPer100g: 15, carbPer100g: 1, fatPer100g: 29, icon: '🥓'),
  // ========== 蛋类 ==========
  Food(id: 'f201', name: '煮鸡蛋', category: FoodCategory.egg, caloriePer100g: 140, proteinPer100g: 13, carbPer100g: 1, fatPer100g: 10, icon: '🥚'),
  Food(id: 'f202', name: '煎鸡蛋', category: FoodCategory.egg, caloriePer100g: 198, proteinPer100g: 13, carbPer100g: 1, fatPer100g: 16, icon: '🍳'),
  Food(id: 'f203', name: '鸡蛋羹', category: FoodCategory.egg, caloriePer100g: 94, proteinPer100g: 10, carbPer100g: 2, fatPer100g: 5, icon: '🍳'),
  Food(id: 'f204', name: '咸鸭蛋', category: FoodCategory.egg, caloriePer100g: 190, proteinPer100g: 12, carbPer100g: 4, fatPer100g: 14, icon: '🥚'),
  Food(id: 'f205', name: '皮蛋', category: FoodCategory.egg, caloriePer100g: 171, proteinPer100g: 13, carbPer100g: 5, fatPer100g: 11, icon: '🥚'),
  Food(id: 'f206', name: '鹌鹑蛋', category: FoodCategory.egg, caloriePer100g: 160, proteinPer100g: 13, carbPer100g: 1, fatPer100g: 12, icon: '🥚'),
  // ========== 水产 ==========
  Food(id: 'f301', name: '鲈鱼', category: FoodCategory.seafood, caloriePer100g: 103, proteinPer100g: 18, carbPer100g: 0, fatPer100g: 3, icon: '🐟'),
  Food(id: 'f302', name: '草鱼', category: FoodCategory.seafood, caloriePer100g: 113, proteinPer100g: 16, carbPer100g: 0, fatPer100g: 5, icon: '🐟'),
  Food(id: 'f303', name: '三文鱼', category: FoodCategory.seafood, caloriePer100g: 139, proteinPer100g: 17, carbPer100g: 0, fatPer100g: 8, icon: '🐟'),
  Food(id: 'f304', name: '鳕鱼', category: FoodCategory.seafood, caloriePer100g: 88, proteinPer100g: 18, carbPer100g: 0, fatPer100g: 1, icon: '🐟'),
  Food(id: 'f305', name: '虾仁', category: FoodCategory.seafood, caloriePer100g: 99, proteinPer100g: 20, carbPer100g: 1, fatPer100g: 1.5, icon: '🦐'),
  Food(id: 'f306', name: '大虾', category: FoodCategory.seafood, caloriePer100g: 93, proteinPer100g: 19, carbPer100g: 0, fatPer100g: 2, icon: '🦐'),
  Food(id: 'f307', name: '螃蟹', category: FoodCategory.seafood, caloriePer100g: 103, proteinPer100g: 16, carbPer100g: 2, fatPer100g: 3, icon: '🦀'),
  Food(id: 'f308', name: '扇贝', category: FoodCategory.seafood, caloriePer100g: 60, proteinPer100g: 11, carbPer100g: 3, fatPer100g: 0.5, icon: '🦪'),
  Food(id: 'f309', name: '海参', category: FoodCategory.seafood, caloriePer100g: 71, proteinPer100g: 15, carbPer100g: 1, fatPer100g: 0.5, icon: '🥒'),
  Food(id: 'f310', name: '鱿鱼', category: FoodCategory.seafood, caloriePer100g: 92, proteinPer100g: 15, carbPer100g: 3, fatPer100g: 2, icon: '🦑'),
  // ========== 蔬菜 ==========
  Food(id: 'f401', name: '西兰花', category: FoodCategory.vegetable, caloriePer100g: 35, proteinPer100g: 3, carbPer100g: 5, fatPer100g: 0.5, icon: '🥦'),
  Food(id: 'f402', name: '菠菜', category: FoodCategory.vegetable, caloriePer100g: 24, proteinPer100g: 2.5, carbPer100g: 3.5, fatPer100g: 0.3, icon: '🥬'),
  Food(id: 'f403', name: '白菜', category: FoodCategory.vegetable, caloriePer100g: 17, proteinPer100g: 1.5, carbPer100g: 3, fatPer100g: 0.1, icon: '🥬'),
  Food(id: 'f404', name: '油菜', category: FoodCategory.vegetable, caloriePer100g: 23, proteinPer100g: 2, carbPer100g: 3, fatPer100g: 0.3, icon: '🥬'),
  Food(id: 'f405', name: '生菜', category: FoodCategory.vegetable, caloriePer100g: 15, proteinPer100g: 1.5, carbPer100g: 2.5, fatPer100g: 0.2, icon: '🥬'),
  Food(id: 'f406', name: '黄瓜', category: FoodCategory.vegetable, caloriePer100g: 15, proteinPer100g: 0.8, carbPer100g: 3, fatPer100g: 0.1, icon: '🥒'),
  Food(id: 'f407', name: '西红柿', category: FoodCategory.vegetable, caloriePer100g: 19, proteinPer100g: 1, carbPer100g: 4, fatPer100g: 0.2, icon: '🍅'),
  Food(id: 'f408', name: '茄子', category: FoodCategory.vegetable, caloriePer100g: 21, proteinPer100g: 1, carbPer100g: 4.5, fatPer100g: 0.2, icon: '🍆'),
  Food(id: 'f409', name: '青椒', category: FoodCategory.vegetable, caloriePer100g: 22, proteinPer100g: 1, carbPer100g: 5, fatPer100g: 0.2, icon: '🫑'),
  Food(id: 'f410', name: '胡萝卜', category: FoodCategory.vegetable, caloriePer100g: 35, proteinPer100g: 1, carbPer100g: 8, fatPer100g: 0.2, icon: '🥕'),
  Food(id: 'f411', name: '白萝卜', category: FoodCategory.vegetable, caloriePer100g: 16, proteinPer100g: 0.6, carbPer100g: 4, fatPer100g: 0.1, icon: '🥕'),
  Food(id: 'f412', name: '芹菜', category: FoodCategory.vegetable, caloriePer100g: 14, proteinPer100g: 0.5, carbPer100g: 3, fatPer100g: 0.1, icon: '🥬'),
  Food(id: 'f413', name: '豆角', category: FoodCategory.vegetable, caloriePer100g: 34, proteinPer100g: 2.5, carbPer100g: 6, fatPer100g: 0.2, icon: '🫘'),
  Food(id: 'f414', name: '豆腐', category: FoodCategory.vegetable, caloriePer100g: 81, proteinPer100g: 8, carbPer100g: 4, fatPer100g: 4, icon: '🧈'),
  Food(id: 'f415', name: '内酯豆腐', category: FoodCategory.vegetable, caloriePer100g: 50, proteinPer100g: 5, carbPer100g: 2, fatPer100g: 2, icon: '🧈'),
  Food(id: 'f416', name: '香菇', category: FoodCategory.vegetable, caloriePer100g: 26, proteinPer100g: 2.5, carbPer100g: 4.5, fatPer100g: 0.3, icon: '🍄'),
  Food(id: 'f417', name: '金针菇', category: FoodCategory.vegetable, caloriePer100g: 26, proteinPer100g: 2.5, carbPer100g: 4.5, fatPer100g: 0.3, icon: '🍄'),
  Food(id: 'f418', name: '木耳', category: FoodCategory.vegetable, caloriePer100g: 21, proteinPer100g: 1.5, carbPer100g: 4.5, fatPer100g: 0.2, icon: '🍄'),
  Food(id: 'f419', name: '海带', category: FoodCategory.vegetable, caloriePer100g: 12, proteinPer100g: 1, carbPer100g: 2, fatPer100g: 0.1, icon: '🌿'),
  Food(id: 'f420', name: '南瓜', category: FoodCategory.vegetable, caloriePer100g: 22, proteinPer100g: 0.7, carbPer100g: 5, fatPer100g: 0.1, icon: '🎃'),
  Food(id: 'f421', name: '冬瓜', category: FoodCategory.vegetable, caloriePer100g: 10, proteinPer100g: 0.3, carbPer100g: 2, fatPer100g: 0.1, icon: '🎃'),
  Food(id: 'f422', name: '莲藕', category: FoodCategory.vegetable, caloriePer100g: 47, proteinPer100g: 1.5, carbPer100g: 11, fatPer100g: 0.2, icon: '🥔'),
  // ========== 水果 ==========
  Food(id: 'f501', name: '苹果', category: FoodCategory.fruit, caloriePer100g: 52, proteinPer100g: 0.3, carbPer100g: 14, fatPer100g: 0.2, icon: '🍎'),
  Food(id: 'f502', name: '香蕉', category: FoodCategory.fruit, caloriePer100g: 93, proteinPer100g: 1.4, carbPer100g: 23, fatPer100g: 0.2, icon: '🍌'),
  Food(id: 'f503', name: '橙子', category: FoodCategory.fruit, caloriePer100g: 48, proteinPer100g: 1, carbPer100g: 12, fatPer100g: 0.1, icon: '🍊'),
  Food(id: 'f504', name: '葡萄', category: FoodCategory.fruit, caloriePer100g: 67, proteinPer100g: 0.6, carbPer100g: 17, fatPer100g: 0.2, icon: '🍇'),
  Food(id: 'f505', name: '西瓜', category: FoodCategory.fruit, caloriePer100g: 30, proteinPer100g: 0.6, carbPer100g: 8, fatPer100g: 0.1, icon: '🍉'),
  Food(id: 'f506', name: '火龙果', category: FoodCategory.fruit, caloriePer100g: 51, proteinPer100g: 1.1, carbPer100g: 13, fatPer100g: 0.2, icon: '🐉'),
  Food(id: 'f507', name: '猕猴桃', category: FoodCategory.fruit, caloriePer100g: 59, proteinPer100g: 1.1, carbPer100g: 14.5, fatPer100g: 0.4, icon: '🥝'),
  Food(id: 'f508', name: '草莓', category: FoodCategory.fruit, caloriePer100g: 32, proteinPer100g: 1, carbPer100g: 7.5, fatPer100g: 0.3, icon: '🍓'),
  Food(id: 'f509', name: '蓝莓', category: FoodCategory.fruit, caloriePer100g: 57, proteinPer100g: 0.7, carbPer100g: 14, fatPer100g: 0.3, icon: '🫐'),
  Food(id: 'f510', name: '芒果', category: FoodCategory.fruit, caloriePer100g: 65, proteinPer100g: 0.9, carbPer100g: 17, fatPer100g: 0.3, icon: '🥭'),
  Food(id: 'f511', name: '菠萝', category: FoodCategory.fruit, caloriePer100g: 44, proteinPer100g: 0.5, carbPer100g: 11, fatPer100g: 0.1, icon: '🍍'),
  Food(id: 'f512', name: '柚子', category: FoodCategory.fruit, caloriePer100g: 42, proteinPer100g: 0.8, carbPer100g: 10.5, fatPer100g: 0.2, icon: '🍊'),
  Food(id: 'f513', name: '梨', category: FoodCategory.fruit, caloriePer100g: 51, proteinPer100g: 0.3, carbPer100g: 13, fatPer100g: 0.1, icon: '🍐'),
  Food(id: 'f514', name: '桃子', category: FoodCategory.fruit, caloriePer100g: 42, proteinPer100g: 0.9, carbPer100g: 10.5, fatPer100g: 0.2, icon: '🍑'),
  Food(id: 'f515', name: '樱桃', category: FoodCategory.fruit, caloriePer100g: 63, proteinPer100g: 1.1, carbPer100g: 16, fatPer100g: 0.2, icon: '🍒'),
  Food(id: 'f516', name: '荔枝', category: FoodCategory.fruit, caloriePer100g: 71, proteinPer100g: 1, carbPer100g: 17, fatPer100g: 0.3, icon: '🍒'),
  // ========== 奶制品 ==========
  Food(id: 'f601', name: '牛奶', category: FoodCategory.dairy, caloriePer100g: 65, proteinPer100g: 3.2, carbPer100g: 4.8, fatPer100g: 3.3, icon: '🥛'),
  Food(id: 'f602', name: '脱脂牛奶', category: FoodCategory.dairy, caloriePer100g: 34, proteinPer100g: 3.4, carbPer100g: 5, fatPer100g: 0.1, icon: '🥛'),
  Food(id: 'f603', name: '酸奶', category: FoodCategory.dairy, caloriePer100g: 72, proteinPer100g: 2.5, carbPer100g: 10, fatPer100g: 2.2, icon: '🥛'),
  Food(id: 'f604', name: '奶酪', category: FoodCategory.dairy, caloriePer100g: 328, proteinPer100g: 23, carbPer100g: 1.5, fatPer100g: 26, icon: '🧀'),
  Food(id: 'f605', name: '黄油', category: FoodCategory.dairy, caloriePer100g: 717, proteinPer100g: 1, carbPer100g: 0.1, fatPer100g: 81, icon: '🧈'),
  Food(id: 'f606', name: '豆浆', category: FoodCategory.dairy, caloriePer100g: 33, proteinPer100g: 3, carbPer100g: 1.8, fatPer100g: 1.6, icon: '🥛'),
  // ========== 零食 ==========
  Food(id: 'f701', name: '薯片', category: FoodCategory.snack, caloriePer100g: 548, proteinPer100g: 7, carbPer100g: 53, fatPer100g: 35, icon: '🍿'),
  Food(id: 'f702', name: '饼干', category: FoodCategory.snack, caloriePer100g: 435, proteinPer100g: 6, carbPer100g: 70, fatPer100g: 15, icon: '🍪'),
  Food(id: 'f703', name: '巧克力', category: FoodCategory.snack, caloriePer100g: 546, proteinPer100g: 5, carbPer100g: 60, fatPer100g: 31, icon: '🍫'),
  Food(id: 'f704', name: '蛋糕', category: FoodCategory.snack, caloriePer100g: 347, proteinPer100g: 5, carbPer100g: 51, fatPer100g: 14, icon: '🍰'),
  Food(id: 'f705', name: '冰淇淋', category: FoodCategory.snack, caloriePer100g: 207, proteinPer100g: 3.5, carbPer100g: 24, fatPer100g: 11, icon: '🍦'),
  Food(id: 'f706', name: '奶茶', category: FoodCategory.snack, caloriePer100g: 67, proteinPer100g: 0.8, carbPer100g: 11, fatPer100g: 2, icon: '🧋'),
  Food(id: 'f707', name: '坚果', category: FoodCategory.snack, caloriePer100g: 607, proteinPer100g: 20, carbPer100g: 15, fatPer100g: 54, icon: '🥜'),
  Food(id: 'f708', name: '牛肉干', category: FoodCategory.snack, caloriePer100g: 410, proteinPer100g: 45, carbPer100g: 15, fatPer100g: 18, icon: '🥩'),
  // ========== 饮料 ==========
  Food(id: 'f801', name: '可乐', category: FoodCategory.drink, caloriePer100g: 42, proteinPer100g: 0, carbPer100g: 11, fatPer100g: 0, icon: '🥤'),
  Food(id: 'f802', name: '橙汁', category: FoodCategory.drink, caloriePer100g: 45, proteinPer100g: 0.7, carbPer100g: 10, fatPer100g: 0.2, icon: '🧃'),
  Food(id: 'f803', name: '椰子水', category: FoodCategory.drink, caloriePer100g: 19, proteinPer100g: 0.7, carbPer100g: 3.7, fatPer100g: 0.2, icon: '🥥'),
  Food(id: 'f804', name: '咖啡', category: FoodCategory.drink, caloriePer100g: 4, proteinPer100g: 0.3, carbPer100g: 0.5, fatPer100g: 0, icon: '☕'),
  Food(id: 'f805', name: '绿茶', category: FoodCategory.drink, caloriePer100g: 1, proteinPer100g: 0, carbPer100g: 0.2, fatPer100g: 0, icon: '🍵'),
];

// 按分类获取食物
Map<String, List<Food>> getFoodsByCategory() {
  final Map<String, List<Food>> result = {};
  for (final food in foodDatabase) {
    result.putIfAbsent(food.category, () => []).add(food);
  }
  return result;
}

// 搜索食物
List<Food> searchFoods(String keyword) {
  final lower = keyword.toLowerCase();
  return foodDatabase.where((f) => f.name.toLowerCase().contains(lower)).toList();
}
