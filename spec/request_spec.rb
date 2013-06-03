require_relative "spec_helper"

module Nyara
  describe [Request, Controller] do
    before :each do
      Request.clear_route
      @e1 = RouteEntry.new{
        @scope = '/hello'
        @prefix = '/hello/'
        @suffix = '(\d+)world'
        @id = :'#1'
        @conv = [:to_i]
        @controller = 'stub'
      }
      @e2 = RouteEntry.new{
        @scope = '/hello'
        @prefix = '/hello'
        @suffix = ''
        @id = :'#second'
        @conv = []
        @controller = 'stub2'
      }
      @e3 = RouteEntry.new{
        @scope = '/a目录'
        @prefix = '/a目录/'
        @suffix = '(\d+)-(\d+)-(\d+)'
        @id = :'#dir'
        @conv = [:to_i, :to_i, :to_i]
        @controller = 'stub3'
      }
      Request.register_route @e1
      Request.register_route @e2
      Request.register_route @e3
    end

    after :all do
      Request.clear_route
    end

    it '#register_route sub-prefix optimization' do
      rules = Request.inspect_route
      assert_equal 3, rules.size

      assert_equal false, rules[0].first # first
      assert_equal true, rules[1].first  # is sub of prev
      assert_equal false, rules[2].first # not sub of prev
    end

    it '#search_route' do
      scope, cont, args = Request.search_route '/hello'
      assert_equal @e2.scope, scope
      assert_equal @e2.controller, cont
      assert_equal [:'#second'], args

      scope, cont, args = Request.search_route '/hello/3world'
      assert_equal @e1.scope, scope
      assert_equal @e1.controller, cont
      assert_equal [:'#1', 3], args

      scope, _ = Request.search_route '/world'
      assert_equal nil, scope

      scope, _, args = Request.search_route '/a目录/2013-6-1'
      assert_equal [:'#dir', 2013, 6, 1], args
    end
  end
end
