require "cases/helper"
require 'models/face'
require 'models/interest'
require 'models/man'
require 'models/topic'

class AbsenceValidationTest < ActiveRecord::TestCase
  def test_non_association
    boy_klass = Class.new(Man) do
      def self.name; "Boy" end
      validates_absence_of :name
    end

    assert boy_klass.new.valid?
    assert_not boy_klass.new(name: "Alex").valid?
  end

  def test_has_one_marked_for_destruction
    boy_klass = Class.new(Man) do
      def self.name; "Boy" end
      validates_absence_of :face
    end

    boy = boy_klass.new(face: Face.new)
    assert_not boy.valid?, "should not be valid if has_one association is present"
    assert_equal 1, boy.errors[:face].size, "should only add one error"

    boy.face.mark_for_destruction
    assert boy.valid?, "should be valid if association is marked for destruction"
  end

  def test_has_many_marked_for_destruction
    boy_klass = Class.new(Man) do
      def self.name; "Boy" end
      validates_absence_of :interests
    end
    boy = boy_klass.new
    boy.interests << [i1 = Interest.new, i2 = Interest.new]
    assert_not boy.valid?, "should not be valid if has_many association is present"

    i1.mark_for_destruction
    assert_not boy.valid?, "should not be valid if has_many association is present"

    i2.mark_for_destruction
    assert boy.valid?
  end

  def test_does_not_call_to_a_on_associations
    boy_klass = Class.new(Man) do
      def self.name; "Boy" end
      validates_absence_of :face
    end

    face_with_to_a = Face.new
    def face_with_to_a.to_a; ['(/)', '(\)']; end

    assert_nothing_raised { boy_klass.new(face: face_with_to_a).valid? }
  end

  def test_does_not_validate_if_parent_record_is_validate_false
    repair_validations(Interest) do
      Interest.validates_absence_of(:topic)
      interest = Interest.new(topic: Topic.new(title: "Math"))
      interest.save!(validate: false)
      assert interest.persisted?

      man = Man.new(interest_ids: [interest.id])
      man.save!

      assert_equal man.interests.size, 1
      assert interest.valid?
      assert man.valid?
    end
  end
end
