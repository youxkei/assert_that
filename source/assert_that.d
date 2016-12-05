module assert_that;


mixin template assertThat(string name, alias lhs, alias matcher)
{
    int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
    {
        import std.format : format;

        mixin("auto %s = %s;".format(name, lhs));
        mixin assertThat!(name, matcher);

        return 0;
    }();
}

mixin template assertThat(string lhs, alias matcher)
{
    int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
    {
        import std.conv : to;
        import std.string : join;

        mixin matcher.match!(lhs, matcher.args);

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
            import std.conv : to;

            static if (__traits(compiles, !mixin(lhs ~ operator ~ rhs.stringof)))
                mixin(
                    "#line %d \"%s\"\n".format(line, file) ~
                    q{assert(mixin(lhs ~ operator ~ rhs.stringof), lhs ~ ": actual " ~ mixin(lhs).to!string ~ ": expected " ~ operator ~ " " ~ rhs.to!string);}
                );
            else
                mixin(
                    "#line %d \"%s\"\n".format(line, file) ~
                    q{assert(false, lhs ~ ": invalid expression: " ~ lhs ~ " " ~ operator ~ " " ~ rhs);}
                );

            return 0;
        }();
    }
}

template eq(alias rhs, string file = __FILE__, ulong line = __LINE__)
{
    alias eq = op!("==", rhs, file, line);
}


template array(string file = __FILE__, ulong line = __LINE__)
{
    template _(matchers...)
    {
        import std.meta : AliasSeq;
        alias args = AliasSeq!(file, line, matchers);

        mixin template match(string lhs, string file, ulong line, matchers...)
        {
            int VARIABLE_FOR_ASSERT_THAT_DONT_REFER_ME = ()
            {
                import assert_that : eq;

                mixin eq!0.match!(lhs ~ ".length", "==", matchers.length, file, line);

                foreach (i, matcher; matchers)
                {
                    import std.conv : to;

                    mixin matcher.match!(lhs ~ "[" ~ i.to!string ~  "]", matcher.args);
                }

                return 0;
            }();
        }
    }
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
                mixin(
                    "#line %d \"%s\"\n".format(line, file) ~
                    q{assert(false, lhs ~ "." ~ fieldName ~ ": field '" ~ fieldName ~ "' does not exist");}
                );

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
