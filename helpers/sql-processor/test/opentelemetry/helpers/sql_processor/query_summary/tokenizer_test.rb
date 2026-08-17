# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/tokenizer'

class TokenizerTest < Minitest::Test
  # Use aliases for cleaner test code
  Tokenizer = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Tokenizer

  def test_keywords_constant_is_frozen_hash
    assert_instance_of Hash, Tokenizer::KEYWORDS
    assert Tokenizer::KEYWORDS.frozen?
    assert Tokenizer::KEYWORDS['SELECT']
    assert Tokenizer::KEYWORDS['INSERT']
    assert Tokenizer::KEYWORDS['FROM']
    refute Tokenizer::KEYWORDS['users']
  end

  def test_keywords_array_contains_expected_keywords
    assert_includes Tokenizer::KEYWORDS_ARRAY, 'SELECT'
    assert_includes Tokenizer::KEYWORDS_ARRAY, 'CREATE'
    assert_includes Tokenizer::KEYWORDS_ARRAY, 'UNION'
    assert_includes Tokenizer::KEYWORDS_ARRAY, 'JOIN'
  end

  def test_tokenize_simple_select_query
    tokens = Tokenizer.tokenize('SELECT * FROM users')

    expected = [
      [:keyword, 'SELECT'],
      [:operator, '*'],
      [:keyword, 'FROM'],
      [:identifier, 'users']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_with_where_condition
    tokens = Tokenizer.tokenize('SELECT id FROM users WHERE age > 21')

    expected = [
      [:keyword, 'SELECT'],
      [:identifier, 'id'],
      [:keyword, 'FROM'],
      [:identifier, 'users'],
      [:keyword, 'WHERE'],
      [:identifier, 'age'],
      [:operator, '>'],
      [:numeric, '21']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_with_string_literals
    tokens = Tokenizer.tokenize("SELECT name FROM users WHERE city = 'New York'")

    expected = [
      [:keyword, 'SELECT'],
      [:identifier, 'name'],
      [:keyword, 'FROM'],
      [:identifier, 'users'],
      [:keyword, 'WHERE'],
      [:identifier, 'city'],
      [:operator, '='],
      [:string, "'New York'"]
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_with_escaped_quotes_in_string
    tokens = Tokenizer.tokenize("SELECT name FROM users WHERE name = 'O''Brien'")

    # Should capture the full string including escaped quote
    string_token = tokens.find { |token| token[0] == :string }
    assert_equal [:string, "'O''Brien'"], string_token
  end

  def test_tokenize_quoted_identifiers_double_quotes
    tokens = Tokenizer.tokenize('SELECT "user name" FROM "user table"')

    expected = [
      [:keyword, 'SELECT'],
      [:quoted_identifier, '"user name"'],
      [:keyword, 'FROM'],
      [:quoted_identifier, '"user table"']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_quoted_identifiers_backticks
    tokens = Tokenizer.tokenize('SELECT `user name` FROM `user table`')

    expected = [
      [:keyword, 'SELECT'],
      [:quoted_identifier, '`user name`'],
      [:keyword, 'FROM'],
      [:quoted_identifier, '`user table`']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_quoted_identifiers_brackets
    tokens = Tokenizer.tokenize('SELECT [user name] FROM [user table]')

    expected = [
      [:keyword, 'SELECT'],
      [:quoted_identifier, '[user name]'],
      [:keyword, 'FROM'],
      [:quoted_identifier, '[user table]']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_various_operators
    tokens = Tokenizer.tokenize('SELECT * FROM users WHERE a <= b AND c >= d AND e <> f AND g != h')

    operators = tokens.select { |token| token[0] == :operator }.map { |token| token[1] }
    assert_includes operators, '<='
    assert_includes operators, '>='
    assert_includes operators, '<>'
    assert_includes operators, '!='
    assert_includes operators, '*'
  end

  def test_tokenize_numeric_values
    tokens = Tokenizer.tokenize('SELECT * FROM users WHERE age = 25 AND price = 19.99 AND factor = -3.14')

    numbers = tokens.select { |token| token[0] == :numeric }.map { |token| token[1] }
    assert_includes numbers, '25'
    assert_includes numbers, '19.99'
    assert_includes numbers, '3.14' # The minus is a separate operator token

    # Verify the minus is parsed as a separate operator
    operators = tokens.select { |token| token[0] == :operator }.map { |token| token[1] }
    assert_includes operators, '-'
  end

  def test_tokenize_scientific_notation
    tokens = Tokenizer.tokenize('SELECT * FROM data WHERE value = 1.23e-4')

    scientific_number = tokens.find { |token| token[0] == :numeric && token[1].include?('e') }
    assert_equal [:numeric, '1.23e-4'], scientific_number
  end

  def test_tokenize_with_variables
    tokens = Tokenizer.tokenize('SELECT * FROM users WHERE id = @user_id')

    variable_token = tokens.find { |token| token[1].start_with?('@') }
    assert_equal [:identifier, '@user_id'], variable_token
  end

  def test_tokenize_schema_qualified_identifiers
    tokens = Tokenizer.tokenize('SELECT * FROM schema.users')

    schema_table_token = tokens.find { |token| token[1].include?('.') }
    assert_equal [:identifier, 'schema.users'], schema_table_token
  end

  def test_tokenize_ignores_line_comments
    tokens = Tokenizer.tokenize("SELECT * FROM users -- This is a comment\nWHERE id = 1")

    # Should not include comment content
    comment_tokens = tokens.select { |token| token[1].include?('comment') }
    assert_empty comment_tokens

    # Should still parse the rest
    assert_includes tokens, [:keyword, 'SELECT']
    assert_includes tokens, [:keyword, 'WHERE']
    assert_includes tokens, [:numeric, '1']
  end

  def test_tokenize_ignores_block_comments
    tokens = Tokenizer.tokenize('SELECT * /* block comment */ FROM users')

    # Should not include comment content
    comment_tokens = tokens.select { |token| token[1].include?('comment') }
    assert_empty comment_tokens

    # Should still parse the rest
    expected = [
      [:keyword, 'SELECT'],
      [:operator, '*'],
      [:keyword, 'FROM'],
      [:identifier, 'users']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_multi_line_block_comment
    query = <<~SQL
      SELECT *
      /*
        Multi-line
        block comment
      */
      FROM users
    SQL

    tokens = Tokenizer.tokenize(query)

    expected = [
      [:keyword, 'SELECT'],
      [:operator, '*'],
      [:keyword, 'FROM'],
      [:identifier, 'users']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_with_parentheses_and_punctuation
    tokens = Tokenizer.tokenize('SELECT COUNT(*) FROM users WHERE id IN (1, 2, 3);')

    expected = [
      [:keyword, 'SELECT'],
      [:identifier, 'COUNT'],
      [:operator, '('],
      [:operator, '*'],
      [:operator, ')'],
      [:keyword, 'FROM'],
      [:identifier, 'users'],
      [:keyword, 'WHERE'],
      [:identifier, 'id'],
      [:keyword, 'IN'],
      [:operator, '('],
      [:numeric, '1'],
      [:operator, ','],
      [:numeric, '2'],
      [:operator, ','],
      [:numeric, '3'],
      [:operator, ')'],
      [:operator, ';']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_case_insensitive_keywords
    tokens = Tokenizer.tokenize('select * from Users WHERE Age > 21')

    # Keywords should be recognized regardless of case
    keyword_tokens = tokens.select { |token| token[0] == :keyword }
    keyword_values = keyword_tokens.map { |token| token[1] }

    assert_includes keyword_values, 'select'
    assert_includes keyword_values, 'from'
    assert_includes keyword_values, 'WHERE'
  end

  def test_tokenize_complex_query
    query = <<~SQL
      WITH user_stats AS (
        SELECT user_id, COUNT(*) as order_count
        FROM orders
        WHERE created_at >= '2023-01-01'
        GROUP BY user_id
      )
      SELECT u.name, us.order_count
      FROM users u
      JOIN user_stats us ON u.id = us.user_id
      WHERE us.order_count > 5
    SQL

    tokens = Tokenizer.tokenize(query)

    # Verify it contains expected token types
    token_types = tokens.map { |token| token[0] }.uniq
    assert_includes token_types, :keyword
    assert_includes token_types, :identifier
    assert_includes token_types, :operator
    assert_includes token_types, :numeric
    assert_includes token_types, :string

    # Verify specific important tokens
    assert_includes tokens, [:keyword, 'WITH']
    assert_includes tokens, [:keyword, 'SELECT']
    assert_includes tokens, [:keyword, 'FROM']
    assert_includes tokens, [:keyword, 'JOIN']
    assert_includes tokens, [:string, "'2023-01-01'"]
    assert_includes tokens, [:numeric, '5']
  end

  def test_tokenize_empty_string
    tokens = Tokenizer.tokenize('')
    assert_empty tokens
  end

  def test_tokenize_only_whitespace
    tokens = Tokenizer.tokenize("   \n\t  \r\n  ")
    assert_empty tokens
  end

  def test_tokenize_only_comments
    tokens = Tokenizer.tokenize("-- Just a comment\n/* Another comment */")
    assert_empty tokens
  end

  def test_tokenize_unicode_identifiers
    # Test Unicode support in identifiers
    tokens = Tokenizer.tokenize('SELECT * FROM utilisateurs WHERE âge > 21')

    unicode_identifier = tokens.find { |token| token[1] == 'utilisateurs' }
    assert_equal [:identifier, 'utilisateurs'], unicode_identifier

    unicode_column = tokens.find { |token| token[1] == 'âge' }
    assert_equal [:identifier, 'âge'], unicode_column
  end

  def test_tokenize_handles_unicode_characters
    # Test that unicode characters in identifiers are handled
    tokens = Tokenizer.tokenize('SELECT * FROM users © WHERE id = 1')

    # Should continue parsing normally
    assert_includes tokens, [:keyword, 'SELECT']
    assert_includes tokens, [:keyword, 'WHERE']
    assert_includes tokens, [:numeric, '1']

    # Unicode characters are included in identifiers by the regex
    unicode_tokens = tokens.select { |token| token[1].include?('©') }
    assert_equal 1, unicode_tokens.length
    assert_equal :identifier, unicode_tokens[0][0]
  end

  def test_tokenize_skips_truly_unmatched_characters
    # Test with a character that should be skipped (ASCII control character)
    tokens = Tokenizer.tokenize("SELECT\x00 * FROM users")

    # Should continue parsing and skip the null character
    expected = [
      [:keyword, 'SELECT'],
      [:operator, '*'],
      [:keyword, 'FROM'],
      [:identifier, 'users']
    ]

    assert_equal expected, tokens
  end

  def test_tokenize_preserves_original_case_in_identifiers
    tokens = Tokenizer.tokenize('SELECT UserName FROM MyTable')

    # Identifiers should preserve original case
    assert_includes tokens, [:identifier, 'UserName']
    assert_includes tokens, [:identifier, 'MyTable']
  end

  def test_tokenize_preserves_original_case_in_keywords
    tokens = Tokenizer.tokenize('Select * From users')

    # Keywords should preserve original case
    assert_includes tokens, [:keyword, 'Select']
    assert_includes tokens, [:keyword, 'From']
  end

  def test_tokens_are_frozen
    tokens = Tokenizer.tokenize('SELECT users FROM table')

    # All token values should be frozen for performance
    tokens.each do |token|
      assert token[1].frozen?, "Token value '#{token[1]}' should be frozen"
    end
  end

  def test_decimal_numbers_without_leading_digit
    tokens = Tokenizer.tokenize('SELECT * FROM table WHERE value = .5')

    decimal_token = tokens.find { |token| token[0] == :numeric && token[1] == '.5' }
    assert_equal [:numeric, '.5'], decimal_token
  end

  def test_positive_and_negative_numbers
    tokens = Tokenizer.tokenize('SELECT * FROM table WHERE a = +5 AND b = -10')

    # The tokenizer parses + and - as separate operator tokens
    operators = tokens.select { |token| token[0] == :operator }.map { |token| token[1] }
    assert_includes operators, '+'
    assert_includes operators, '-'

    # The numbers are parsed without the sign
    numbers = tokens.select { |token| token[0] == :numeric }.map { |token| token[1] }
    assert_includes numbers, '5'
    assert_includes numbers, '10'
  end

  def test_arithmetic_operators
    tokens = Tokenizer.tokenize('SELECT a + b - c * d / e % f FROM table')

    operators = tokens.select { |token| token[0] == :operator }.map { |token| token[1] }
    assert_includes operators, '+'
    assert_includes operators, '-'
    assert_includes operators, '*'
    assert_includes operators, '/'
    assert_includes operators, '%'
  end

  def test_classify_identifier_method_correctly_identifies_keywords
    # This tests the private classify_identifier method indirectly
    tokens = Tokenizer.tokenize('SELECT CREATE ALTER')

    # All should be classified as keywords
    tokens.each do |token|
      assert_equal :keyword, token[0]
    end
  end

  def test_classify_identifier_method_correctly_identifies_non_keywords
    tokens = Tokenizer.tokenize('users table_name column1')

    # All should be classified as identifiers
    tokens.each do |token|
      assert_equal :identifier, token[0]
    end
  end

  def test_upcase_caching_functionality
    # Test that the upcase caching works (indirectly through keyword recognition)
    tokens1 = Tokenizer.tokenize('select')
    tokens2 = Tokenizer.tokenize('select') # Should use cached upcase result

    assert_equal :keyword, tokens1[0][0]
    assert_equal :keyword, tokens2[0][0]
    assert_equal tokens1, tokens2
  end
end
