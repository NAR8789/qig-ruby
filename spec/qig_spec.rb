# frozen_string_literal: true

RSpec.describe Qig, :aggregate_failures do
  # Qig combines the powers of dig and jq. Or, it's dig with a jq-like twist.
  # Qig is like dig, but with jq's `[]` operator.
  # That is to say...
  
  context 'it behaves like dig' do
    it 'handles dig documentation examples' # TODO: rephrase this

    it 'handles simple hash cases' do
      expect(Qig.qig({a: 1, b: 2}, :a)).to eq(1)
      expect(Qig.qig({a: 1, b: 2}, :b)).to eq(2)
      expect(Qig.qig({a: 1, b: 2}, :c)).to eq(nil)
      expect(Qig.qig({a: 1, b: 2}, :c, :d)).to eq(nil)
    end

    it 'handles simple array cases' do
      expect(Qig.qig([1, 2], 0)).to eq(1)
      expect(Qig.qig([1, 2], 1)).to eq(2)
      expect(Qig.qig([1, 2], 2)).to eq(nil)
      expect(Qig.qig([1, 2], 2, 0)).to eq(nil)
      expect(Qig.qig([[1, 2], [3, 4]], 0)).to eq([1, 2])
    end

    it 'handles simple struct cases' do
      stub_const('TestStruct', Struct.new('TestStruct', :a, :b))
      expect(Qig.qig(TestStruct.new(1, 2), :a)).to eq 1
    end

    it 'handles simple OpenStruct cases' do
      require 'ostruct'
      expect(Qig.qig(OpenStruct.new(a: 1, b: 2), :a)).to eq 1
    end
  end

  context 'it behaves like jq' do
    xit "doesn't handle the more general-programming aspects of the jq dsl. For that, use ruby idioms instead"

    it 'handles simple jq documentation examples' # TODO: rephrase this
    # example with top-level hash with embedded array

    # in particular then, qig handles []: the unboxing operator
    describe '[]' do
      it 'behaves like flatten, preserving stray atoms (jq raises an error in this case)'
      # we do this because it's more in the spirit of dig's tendency towards "safe" navigation

      it 'unboxes hashes into their values' do
        expect(Qig.qig({ a: 1, b: 2 }, [])).to eq [1, 2]
        expect(Qig.qig({ a: 1, b: 2 }, [], [])).to eq [1, 2]
        expect(Qig.qig([{ a: 1, b: 2 }], [], [])).to eq [1, 2]
        expect(Qig.qig([{ a: 1, b: 2 }], [], [], [])).to eq [1, 2]
      end

      # TODO: wordsmith the rest of the following specs

      it 'treats the first level of [] as array descent' do
        expect(Qig.qig([[1, 2], [3, 4]], [])).to eq([[1, 2], [3, 4]])
        expect(Qig.qig([[1, 2], [3, 4]], [], 0)).to eq([1, 3])
        expect(Qig.qig([[1, 2], [3, 4]], [], 1)).to eq([2, 4])
        expect(Qig.qig([[1, 2], [3, 4]], [], 2)).to eq([nil, nil])
        expect(Qig.qig([[1, 2], [3, 4]], [], 2, 0)).to eq([nil, nil])
      end

      it 'treats further levels of [] as value iteration' do
        expect(Qig.qig([1, [2], [3, [4]]], [], [])).to eq([1, 2, 3, [4]])
        expect(Qig.qig([1, [2], [3, [4]]], [], [], [])).to eq([1, 2, 3, 4])
      end

      it 'WIP experimental examples' do
        array_pyramid = [[[[], []], []], []]
        expect(Qig.qig(array_pyramid)).to                         eq([[[[], []], []], []])
        expect(Qig.qig(array_pyramid, [])).to                     eq([[[[], []], []], []])
        expect(Qig.qig(array_pyramid, [], [])).to                 eq( [[[], []], []])
        expect(Qig.qig(array_pyramid, [], [], [])).to             eq(  [[], []])
        expect(Qig.qig(array_pyramid, [], [], [], [])).to         eq(   [])
        expect(Qig.qig(array_pyramid, [], [], [], [], [])).to     eq(   [])
        expect(Qig.qig(array_pyramid, [], [], [], [], [], [])).to eq(   [])

        expect(Qig.qig(array_pyramid, 0)).to                 eq( [[[], []], []])
        expect(Qig.qig(array_pyramid, [], 0)).to             eq([[[], []],       nil])
        expect(Qig.qig(array_pyramid, [], [], 0)).to         eq([[],             nil])
        expect(Qig.qig(array_pyramid, [], [], [], 0)).to     eq([nil,            nil])
        expect(Qig.qig(array_pyramid, [], [], [], [], 0)).to eq([                   ])

        pyramid = [0, [1, [2, [3]]]]
        expect(Qig.qig(pyramid                )).to eq([0, [1, [2, [3]]]])
        expect(Qig.qig(pyramid, []            )).to eq([0, [1, [2, [3]]]])
        expect(Qig.qig(pyramid, [], []        )).to eq([0,  1, [2, [3]]] )
        expect(Qig.qig(pyramid, [], [], []    )).to eq([0,  1,  2, [3]]  )
        expect(Qig.qig(pyramid, [], [], [], [])).to eq([0,  1,  2,  3]   )
        expect(Qig.qig(pyramid, [], [], [], [])).to eq([0,  1,  2,  3]   )

        eight = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
        expect(Qig.qig(eight, 0)).to          eq([[1, 2], [3, 4]])
        expect(Qig.qig(eight, [], 0)).to      eq([[1, 2], [5, 6]])
        expect(Qig.qig(eight, [], [], 0)).to  eq([1, 3, 5, 7])
        expect(Qig.qig(eight, [], [], [])).to eq([1, 2, 3, 4, 5, 6, 7, 8])
      end
    end
  end

  context 'miscellaneous extensions to dig' do
    it 'handles trivial cases' do
      expect(Qig.qig({})).to eq({})
      expect(Qig.qig([])).to eq([])
      # more specifically, this is jq-like. dig gripes at you if you don't give it a path
    end

    it 'safely navigates top-level nil' do
      expect(Qig.qig(nil, 1, 2 ,3)).to eq(nil)
      # dig safely navigates embedded nils but is not defined on nil for top-level nav
    end
  end

  context 'unit-context vs collection-context' do
    # When working with qig, it's useful to bring in a concept of "unit-context" vs "collection-context".
    # That is: whether qig treats the input to each navigation step as a unit, or as a collection.
    #
    # qig needs this to resolve a fundamental operating difference between dig and jq:
    # dig operates purely on single elements, while jq operates purely on collections of elements.
    # - even when dig is operating on an array, it can index into that array,
    #   but can't map an indexing operation across the underlying elements. It's treating
    #   the array as a single element.
    # - jq's collection is the top-level element stream (as opposed to any individual array).
    #   By the nature of streaming, even when jq is just working with a single element we can
    #   consider it to be working with a collection of one element.
    #
    # This puts peculiar constraints on qig's return type and navigation operations:
    # - jq-like usages require results wrapped in a collection to allow multiple values,
    #   whereas dig-like usages benefit from the ability to return a single value
    #   without a pesky enclosing collection.
    # - when working with arrays, dig-like usages must apply navigation to the top-level
    #   array, whereas jq-like usages need a way to map navigation across a collection.
    #
    # qig solves this by keeping track internally of "unit-context" vs "collection-context".
    # - In unit context, qig treats the input to each step as a _unit_ subject, and uses
    #   dig-like behavior:
    #   - navigation operations apply directly to the top-level
    #   - return value is a unit: its the raw value we dug up, unencpsulated
    # - In collection context, qig treats the input to each step as a _collection_ of subjects, and uses
    #   jq-like behavior:
    #   - navigation operations map across the elements of the top-level collection, one level deep
    #   - return values are encapsulated in a collection (even if there is only one return value)
    #
    # Qig follows simple rules to determine context:
    # - qig always starts in unit-context (always start off assuming the input is an atomic subject)
    # - qig switches to collection-context upon [] (read: "value iteration").
    #
    # This strives for good balance between flexibility and usability:
    # - unit-context retains the intuitive feel of dig-like usage
    # - switching to collection-context is short, explicit, and sticks to jq semantics.

    context 'qig always starts in unit context' do
      it 'treats initial input as a unit, even when that input is an array'
    end

    context 'qig switches to collection context upon first invocation of []' do
      # this can produce some counterintuitive results

      specify 'first [] looks like a no-op' do
        expect(Qig.qig([1, 2, 3], [])).to eq([1,2,3])
      end
      
      specify 'multi-navigation always requires a leading []'

      # but this provides low-cost flexibility, and provides the caller explicit control.

      specify 'first [] looks like a no-op in isolation, but qig updated its internal state. This is apparent on further navigation' do
        # these look the same on the surface...

        expect(Qig.qig([[1, 2], [3, 4]])).to eq([[1, 2], [3, 4]])
        expect(Qig.qig([[1, 2], [3, 4]], [])).to eq([[1, 2], [3, 4]])

        # but the difference is apparent one step further in

        expect(Qig.qig([[1, 2], [3, 4]], 0)).to eq([1, 2])
        expect(Qig.qig([[1, 2], [3, 4]], [], 0)).to eq([1, 3])
      end

      specify 'the leading [] explicitly disambiguates multi-navigation vs direct-indexing'

      # additionally...

      specify 'qig will preserve the type of the outer collection if possible'
    end

    # TODO: move to Decision Record
    #
    # # Alternatives
    #
    # Qig could decide to act like jq, and just treat all inputs as collections and always return
    # a collection. This has two downsides:
    # 1. It makes the dig-like usages less ergonomic (though arguably callers could just switch to dig in those cases)
    # 2. It likely eliminates the ability to dig into top-level arrays, since we'd probably assume these are top-level.
  end
end
