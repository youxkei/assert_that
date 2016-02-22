module assert_that;


mixin template assertThat(string lhs, alias matcher, string file = __FILE__, ulong line = __LINE__)
{
    int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
    {
        import std.conv : to;
        import std.string : join;

        string[] errors;

        mixin matcher.match!(lhs, matcher.args);

        if (errors.length > 0)
            mixin(
                "#line " ~ line.to!string ~ " \"" ~ file ~ "\"\n"
                q{assert(false, "\n" ~ errors.join("\n"));}
            );
            

        return 0;
    }();
}


template op(string operator, alias rhs, string file = __FILE__, ulong line = __LINE__)
{
    import std.meta : AliasSeq;
    alias args = AliasSeq!(operator, rhs, file, line);

    mixin template match(string lhs, string operator, alias rhs, string file, ulong line)
    {
        int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
        {
            import std.format : format;

            static if (!__traits(compiles, !mixin(lhs ~ operator ~ rhs.stringof)))
                errors ~= "%s(%s): %s: invalid expression: %s %s %s".format(file, line, lhs, lhs, operator, rhs);
            else
            {
                if (!mixin(lhs ~ operator ~ rhs.stringof))
                    errors ~= "%s(%s): %s: actual %s: expected %s %s".format(file, line, lhs, mixin(lhs), operator, rhs);
            }

            return 0;
        }();
    }
}

template eq(alias rhs, string file = __FILE__, ulong line = __LINE__)
{
    alias eq = op!("==", rhs, file, line);
}


template arr(alias matchers, string file = __FILE__, ulong line = __LINE__)
{
    import std.meta : AliasSeq;
    alias args = AliasSeq!(file, line, matchers.args);

    mixin template match(string lhs, string file, ulong line, matchers...)
    {
        int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
        {
            mixin eq!0.match!(lhs ~ ".length", "==", matchers.length, file, line);

            foreach (i, matcher; matchers)
            {
                import std.conv : to;

                if (i < mixin(lhs ~ ".length"))
                    mixin matcher.match!(lhs ~ "[" ~ i.to!string ~  "]", matcher.args);
            }

            return 0;
        }();
    }
}

template ay(matchers...)
{
    alias args = matchers;
}


template field(string fieldName, alias matcher, string file = __FILE__, ulong line = __LINE__)
{
    import std.meta : AliasSeq;
    alias args = AliasSeq!(fieldName, matcher, file, line);

    mixin template match(string lhs, string fieldName, alias matcher, string file, ulong line)
    {
        int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
        {
            import std.format : format;

            static if (__traits(compiles, mixin(lhs ~ "." ~ fieldName)))
                mixin matcher.match!(lhs ~ "." ~ fieldName, matcher.args);
            else
                errors ~= "%s(%s): %s.%s: %s does not exist".format(file, line, lhs, fieldName, fieldName);

            return 0;
        }();
    }
}


template all(matchers...)
{
    alias args = matchers;

    mixin template match(string lhs, matchers...)
    {
        int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
        {
            foreach (matcher; matchers)
            {
                mixin matcher.match!(lhs, matcher.args);
            }

            return 0;
        }();
    }
}
