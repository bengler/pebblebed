# Models the checkpoint group access data for one identity
module Pebblebed
  module Security
    class AccessData
      attr_reader :group_ids

      def initialize(data)
        if data[:subtrees] || data[:group_ids]
          @group_ids = Set.new(data[:group_ids])
          @subtrees = Set.new
          data[:subtrees].each do |subtree|
            @subtrees << subtree.split('.')
          end
        else
          # Assume this is a /identities/:id/memberships result from checkpoint
          parse_checkpoint_record(data)
        end
      end

      # Takes a path (possibly with wildcards) and returns
      # any subtrees that are relevant to determine accessibility
      # to restricted content in a query of documents in that
      # wildcard_path. All relevant subtrees are guaranteed to be
      # returned, but not all returned subtrees are guaranteed to be
      # relevant. I.e. some irrelevant subtrees may be returned.
      # (If the path does not use wildcards, relevance is
      # guaranteed.)
      def relevant_subtrees(wildcard_path)
        pristine = self.class.pristine_path(wildcard_path)
        intersecting_subtrees(pristine)
      end

      def subtrees
        @subtrees.map { |subtree| subtree.join('.') }
      end

      private

      # Takes a path possibly containing wildcard characters and returns
      # a superset path that just contains proper labels. E.g. "a.b.c|d.*" returns
      # "a.b"
      def self.pristine_path(wildcard_path)
        result = []
        wildcard_path.split('.').each do |label|
          break unless Pebblebed::Uid.valid_label?(label)
          result << label
        end
        result.join('.')
      end

      # Returns any subtrees that "intersect" the provided location. That is
      # they are either supersets of the location ("a.b" is a superset of "a.b.c")
      # or subsets ("a.b.c.d" is a subset of "a.b.c"). Also exact matches are returned
      # ('a.b.c' matches 'a.b.c', duh!)
      def intersecting_subtrees(location)
        location = location.split('.')
        result = []
        @subtrees.each do |subtree|
          if subtree.length >= location.length
            # is this a subset tree?
            result << subtree if location == subtree[0...location.length]
          else
            # is this a superset tree?
            result << subtree if subtree == location[0...subtree.length]
          end
        end
        result.map { |subtree| subtree.join('.') }
      end

      # Initializes the instance with data from a checkpoint GET /identities/:id/memberships request
      def parse_checkpoint_record(memberships_record)
        @group_ids = Set.new
        @subtrees = Set.new
        memberships_record['memberships'].each do |membership|
          @group_ids << membership['membership']['group_id']
        end
        memberships_record['groups'].each do |group|
          group['group']['subtrees'].each do |subtree|
            @subtrees << subtree.split('.')
          end
        end
      end
    end
  end
end
