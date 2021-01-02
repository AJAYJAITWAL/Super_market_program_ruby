require 'minitest/autorun'

class Item
  attr_accessor :name, :price

  def initialize(name, price)
    self.name = name
    self.price = price
  end
end

class BasketRule
  attr_accessor :min_basket_price, :discount_per

  def initialize(min_basket_price, discount_per)
    self.min_basket_price = min_basket_price
    self.discount_per = discount_per
  end

  def discount(basket_price)
    return 0 if basket_price < min_basket_price
    ((basket_price / 100.0) * discount_per)
  end
end

class ItemRule
  attr_accessor :item, :quantity, :price

  def initialize(item, quantity, price)
    self.item = item
    self.quantity = quantity
    self.price = price
  end

  def discount(item_obj, item_qty)
    return 0 unless item_obj.name == item.name

    dis = (item.price * quantity) - price
    ((item_qty / quantity) * dis)
  end
end

class Checkout
  attr_accessor :items, :pricing_rules, :total_price

  def initialize(pricing_rules)
    self.items = {}
    self.pricing_rules = pricing_rules
  end

  def scan(item)
    self.items[item.name] ||= []
    self.items[item.name] << item
  end

  def total
    apply_rules
    total_price
  end

  private

  def item_rules
    pricing_rules.select{ |r| r.is_a? ItemRule }
  end

  def basket_rules
    pricing_rules.select{ |r| r.is_a? BasketRule }
  end

  def apply_item_rules
    items_price = self.items.values.collect do |list|
      discount = item_rules.collect{ |r| r.discount(list.first, list.count) }.sum
      (list.first.price * list.count) - discount
    end
    self.total_price = items_price.sum
  end

  def apply_basket_rules
    discount = basket_rules.collect{ |r| r.discount(total_price) }.sum
    self.total_price = total_price - discount
  end

  def apply_rules
    self.total_price = 0
    apply_item_rules
    apply_basket_rules
  end
end

class CheckoutTest < MiniTest::Test
  def setup
    @a = Item.new('A', 50)
    @b = Item.new('B', 30)
    @c = Item.new('C', 20)

    rules1 = ItemRule.new(@a, 2, 90)
    rules2 = ItemRule.new(@b, 3, 75)
    rules3 = BasketRule.new(200, 10)
    pricing_rules = [rules1, rules2, rules3]

    @co = Checkout.new(pricing_rules)
  end

  def test_price_should_be_100_for_a_b_c
    @co.scan(@a)
    @co.scan(@b)
    @co.scan(@c)
    assert_equal(@co.total, 100)
  end

  def test_price_should_be_165_b_a_b_b_a
    @co.scan(@b)
    @co.scan(@a)
    @co.scan(@b)
    @co.scan(@b)
    @co.scan(@a)
    assert_equal(@co.total, 165)
  end

  def test_price_should_be_189_c_b_a_a_c_b_c
    @co.scan(@c)
    @co.scan(@b)
    @co.scan(@a)
    @co.scan(@a)
    @co.scan(@c)
    @co.scan(@b)
    @co.scan(@c)
    assert_equal(@co.total, 189)
  end
end
