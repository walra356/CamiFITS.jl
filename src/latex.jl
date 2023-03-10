# ============= latexIsotopeTable(Z1, Z2; continuation=false) ==================

# ..............................................................................
function _tabline_iterator(Z1::Int, Z2::Int)

    tabline = ""

    indent=false
    for i=Z1:Z2
        indent=false
        for j=1:3i
            str = _texIsotope(i,j;indent)
            isnothing(str) ? false : (tabline *= str; indent=true)
        end
        tabline *= "\\hline\n"
    end

    return tabline

end
# ..............................................................................
function _init_table(Z1::Int, Z2::Int)

    str = "\\setlength{\\tabcolsep}{3pt}"
    str *= "\n\\renewcommand{\\arraystretch}{1.2}"
    str *= "\n\\begin{table}[H]"
    str *= "\n\\centering"
    str *= "\n\\footnotesize"
    str *= "\n\\caption{\\label{table:Isotopes-a-1}"
    str *= "Properties of selected atomic isotopes. "
    str *= "The Table is based on three databases: "
    str *= "(a) AME2020 (atomic mass evaluation); "
    str *= "(b) IAEA-INDC(NDS)-794 (magnetic dipole moments); "
    str *= "(c) IAEA-INDC(NDS)-833 (electric quadrupole moments).}"
    str *= "\n\\begin{tabular}{r|lr|rrrr|r|r|r|r}"
    str *= "\n\\multicolumn{12}{r}\\vspace{-18pt}\\\\"
    str *= "\n\\hline"
    str *= "\n\\hline"
    str *= "\n\$Z\$ & element & symbol & \$A\$ & \$N\$ & radius & atomic mass"
    str *= " & \$I\\,^\\pi\$ & \$\\mu_I \$ & \$Q\$ & \$RA\$\\\\"
    str *= "&  &  &  &  & (fm) & \$(m_u)\$ & \$(\\hbar)\\ \\ \$ & \$(\\mu_N)\$ & (barn) & (\\%)\\\\"
    str *= "\\hline\n"
    str *= _tabline_iterator(Z1, Z2)
    str *= "\\multicolumn{12}{l}{*radioactive }\\\\\n\\end{tabular}"
    str *= "\\end{table}\n"

end
# ..............................................................................
function _continuation_table(Z1::Int, Z2::Int)

    str = "\\newpage"
    str *= "\n\\setlength{\\tabcolsep}{3pt}"
    str *= "\n\\renewcommand{\\arraystretch}{1.2}"
    str *= "\n\\begin{table}"
    str *= "\n\\centering"
    str *= "\n\\footnotesize"
    str *= "\n\\caption*{Table 1.1 (continuation)}"
    str *= "\n\\begin{tabular}{r|lr|rrrr|r|r|r|r}"
    str *= "\n\\multicolumn{12}{r}\\vspace{-18pt}\\\\"
    str *= "\n\\hline"
    str *= "\n\\hline"
    str *= "\n\$Z\$ & element & symbol & \$A\$ & \$N\$ & radius & atomic mass"
    str *= " & \$I\\,^\\pi\$ & \$\\mu_I \$ & \$Q\$ & \$RA\$\\\\"
    str *= "&  &  &  &  & (fm) & \$(m_u)\$ & \$(\\hbar)\\ \\ \$ & \$(\\mu_N)\$ & (barn) & (\\%)\\\\"
    str *= "\\hline\n"
    str *= _tabline_iterator(Z1, Z2)
    str *= "\\end{tabular}"
    str *= "\n\\end{table}\n"

end
# ..............................................................................
@doc raw"""
    latexIsotopeTable(Z1::Int, Z2::Int; continuation=false)

Isotope table for all isotopes with atomic number from `Z1` to `Z2`.
#### Example:
```
latexIsotopeTable(1:3)
  \setlength{\tabcolsep}{3pt}
  \renewcommand{\arraystretch}{1.2}
  \begin{table}[H]
    \centering
    \caption{\label{table:Isotopes-a-1}Properties of selected atomic isotopes. The Table is based on three databases: (a) AME2020 (atomic mass evaluation); (b) IAEA-INDC(NDS)-794 (magnetic dipole moments); (c) IAEA-INDC(NDS)-833 (electric quadrupole moments).}
    \begin{tabular}{r|lr|rrrr|r|r|r|r}
      \multicolumn{12}{r}\vspace{-18pt}\\
      \hline
      \hline
      $Z$ & element & symbol & $A$ & $N$ & radius & atomic mass & $I\,^\pi$ & $\mu_I $ & $Q$ & $RA$\\&  &  &  &  & (fm) & $(m_u)$ & $(\hbar)\ \ $ & $(\mu_N)$ & (barn) & (\%)\\\hline
      1 & hydrogen & $^{1}$H & 1\, & 0 & 0.8783 & 1.007825032 & 1/2$^+$ & 2.792847351 & 0.0 & 99.9855 \\
        &  & $^{2}$H & 2\, & 1 & 2.1421 & 2.014101778 & 1//1$^+$ & 0.857438231 & 0.0028578 & 0.0145 \\
        &  & $^{3}$H & 3$*\!\!$ & 2 & 1.7591 & 3.016049281 & 1/2$^+$ & 2.97896246 & 0.0 & trace \\
      \hline
      2 & helium & $^{3}$He & 3\, & 1 & 1.9661 & 3.016029322 & 1/2$^+$ & -2.12762531 & 0.0 & 0.0002 \\
        &  & $^{4}$He & 4\, & 2 & 1.6755 & 4.002603254 & 0//1$^+$ & 0.0 & 0.0 & 99.9998\% \\
      \hline
      3 & lithium & $^{6}$Li & 6\, & 3 & 2.589 & 6.015122887 & 1//1$^+$ & 0.822043 & -0.000806 & 4.85 \\
        &  & $^{7}$Li & 7\, & 4 & 2.444 & 7.016003434 & 3/2$^-$ & 3.256407 & -0.04 & 95.15 \\
      \hline
      \multicolumn{12}{l}{*radioactive }\\
    \end{tabular}
  \end{table}
```
The typeset result is shown in the figule below.

![Image](./assets/latexIsotopeTable.png)
"""
function latexIsotopeTable(Z1::Int, Z2::Int; continuation=false)

    o = continuation ? _continuation_table(Z1, Z2) : _init_table(Z1, Z2)

    return println(o)

end
function latexIsotopeTable(itrZ::UnitRange; continuation=false)

    return latexIsotopeTable(itrZ.start, irZ.stop; continuation=false)

end
# ================================ End =========================================
