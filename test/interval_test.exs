defmodule Cldr.DateTime.Interval.Test do
  use ExUnit.Case, async: true

  test "Error returns" do
    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             number_system: "unknown"
           ) ==
             {:error, {Cldr.UnknownNumberSystemError, "The number system \"unknown\" is invalid"}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             locale: "unknown"
           ) ==
             {:error, {Cldr.UnknownLocaleError, "The locale \"unknown\" is not known."}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             format: "unknown"
           ) ==
             {:error,
              {Cldr.DateTime.Compiler.ParseError,
               "Could not tokenize \"unk\". Error detected at 'n'"}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             format: :unknown
           ) ==
             {:error,
              {Cldr.DateTime.UnresolvedFormat,
               "The interval format :unknown is invalid. Valid formats are [:long, :medium, :short] or an interval format string."}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             style: :unknown
           ) ==
             {:error,
              {Cldr.DateTime.InvalidStyle,
               "The interval style :unknown is invalid. Valid styles are [:date, :month, :month_and_day, :year_and_month]."}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             style: "unknown"
           ) ==
             {:error,
              {Cldr.DateTime.InvalidStyle,
               "The interval style \"unknown\" is invalid. Valid styles are [:date, :month, :month_and_day, :year_and_month]."}}
  end

  test "that dates in the wrong order return an error" do
    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-12-01], ~D[2020-01-12]), MyApp.Cldr) ==
    {:error,
     {Cldr.DateTime.DateTimeOrderError,
      "Start date/time must be earlier or equal to end date/time. Found ~D[2020-12-01 Cldr.Calendar.Gregorian], ~D[2020-01-12 Cldr.Calendar.Gregorian]."}}
  end

  test "that datetimes in the wrong order return an error" do
    assert Cldr.DateTime.Interval.to_string(~U[2020-02-01 00:00:00.0Z], ~U[2020-01-01 00:00:00.0Z], MyApp.Cldr) ==
    {
      :error,
      {
        Cldr.DateTime.DateTimeOrderError,
        "Start date/time must be earlier or equal to end date/time. Found ~U[2020-02-01 00:00:00.0Z Cldr.Calendar.Gregorian], ~U[2020-01-01 00:00:00.0Z Cldr.Calendar.Gregorian]."
      }
    }
  end

  test "that times in the wrong order return an error" do
    assert Cldr.Time.Interval.to_string(~T[10:00:00], ~T[00:00:00], MyApp.Cldr) ==
    {
      :error,
      {
        Cldr.DateTime.DateTimeOrderError,
        "Start date/time must be earlier or equal to end date/time. Found ~T[10:00:00 Cldr.Calendar.Gregorian], ~T[00:00:00 Cldr.Calendar.Gregorian]."
      }
    }
  end
end
