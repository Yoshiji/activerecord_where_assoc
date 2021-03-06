# frozen_string_literal: true

require "test_helper"

describe "wa_count" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "counts matching has_one through has_one through has_one as at most 1" do
    o1_1 = s0.create_assoc!(:o1, :S0_o1)
    o1_2 = s0.create_assoc!(:o1, :S0_o1)

    o2_11 = o1_1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2_12 = o1_1.create_assoc!(:o2, :S0_o2o1, :S1_o2)

    o2_21 = o1_2.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2_22 = o1_2.create_assoc!(:o2, :S0_o2o1, :S1_o2)

    assert_wa_count(0, :o3o2o1)

    o2_11.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_11.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_12.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_12.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_21.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_21.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_22.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2_22.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)

    assert_wa_count(1, :o3o2o1)
  end

  it "counts matching has_one through a has_one with a source that is a has_one through as at most 1" do
    o1_1 = s0.create_assoc!(:o1, :S0_o1)
    o1_2 = s0.create_assoc!(:o1, :S0_o1)

    o2_11 = o1_1.create_assoc!(:o2, :S1_o2)
    o2_12 = o1_1.create_assoc!(:o2, :S1_o2)

    o2_21 = o1_2.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2_22 = o1_2.create_assoc!(:o2, :S0_o2o1, :S1_o2)

    assert_wa_count(0, :o3o1_o3o2)

    o2_11.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_11.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_12.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_12.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_21.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_21.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_22.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2_22.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)

    assert_wa_count(1, :o3o1_o3o2)
  end
end
